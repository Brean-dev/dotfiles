local lspconfig = require("lspconfig")
local util = require("lspconfig.util")

-- Completion capabilities
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Common LSP keymaps per buffer
local on_attach = function(_, bufnr)
	local map = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
	end

	map("n", "gd", vim.lsp.buf.definition, "Go to definition")
	map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
	map("n", "gr", vim.lsp.buf.references, "References")
	map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
	map("n", "K", vim.lsp.buf.hover, "Hover")
	map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
	map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
	map("n", "<leader>fd", vim.diagnostic.open_float, "Line diagnostics")

	-- Format on save (sync) for Go/Rust
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = bufnr,
		callback = function()
			local ft = vim.bo[bufnr].filetype
			if ft == "go" or ft == "rust" then
				vim.lsp.buf.format({ async = false })
			end
		end,
	})

	-- Inlay hints (Neovim 0.10+)
	if vim.lsp.inlay_hint then
		pcall(vim.lsp.inlay_hint, bufnr, true)
	end
end

-- ===== RUST =====
lspconfig.rust_analyzer.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	root_dir = util.root_pattern("Cargo.toml", ".git"),
	settings = {
		["rust-analyzer"] = {
			cargo = { allFeatures = true },
			checkOnSave = { command = "clippy" },
			diagnostics = { enable = true },
			inlayHints = { enabled = true },
		},
	},
})

-- ===== GO =====
lspconfig.gopls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	root_dir = util.root_pattern("go.work", "go.mod", ".git"),
	settings = {
		gopls = {
			usePlaceholders = true,
			analyses = { unusedparams = true, nilness = true, shadow = true, unusedwrite = true },
			staticcheck = true,
			gofumpt = true,
			expandWorkspaceToModule = true,
			-- Optional: filter noisy dirs if present
			-- directoryFilters = { "-.git", "-node_modules", "-dist", "-target" },
		},
	},
})

-- ===== LUA =====
lspconfig.lua_ls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	root_dir = util.root_pattern(".luarc.json", ".luarc.jsonc", ".git"),
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = {
				checkThirdParty = false,
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = { enable = false },
		},
	},
})

-- ===== Workspace-wide diagnostics (command) =====
-- Uses workspace/diagnostic if supported; falls back to opening files
local function request_workspace_diags(client)
	if client and client.supports_method and client.supports_method("workspace/diagnostic") then
		client.request("workspace/diagnostic", { previousResultIds = {} }, function(_, _)
			vim.schedule(function()
				vim.diagnostic.setqflist({ open = true })
			end)
		end)
		return true
	end
	return false
end

vim.api.nvim_create_user_command("LspScanProject", function()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	for _, c in ipairs(clients) do
		if request_workspace_diags(c) then
			return
		end
	end
	-- Fallback: touch files so servers publish diags (requires ripgrep)
	local root = vim.fn.getcwd()
	local ok, files = pcall(vim.fn.systemlist, "rg --files " .. vim.fn.shellescape(root))
	if ok then
		for _, f in ipairs(files) do
			pcall(vim.cmd.edit, f)
		end
		vim.diagnostic.setqflist({ open = true })
	else
		vim.notify("rg not found; cannot brute-force workspace scan", vim.log.levels.WARN)
	end
end, { desc = "Populate diagnostics for entire workspace" })

-- Toggle focus between editor and QUICKFIX (diagnostics) window
local function qf_toggle_focus()
	local qf = vim.fn.getqflist({ winid = 1 }).winid
	if qf == 0 then
		vim.cmd("copen") -- not open? open it
		qf = vim.fn.getqflist({ winid = 1 }).winid
	end
	if vim.api.nvim_get_current_win() == qf then
		vim.cmd("wincmd p") -- currently in QF -> go back
	else
		vim.api.nvim_set_current_win(qf) -- jump into QF
	end
end
vim.keymap.set("n", "<leader>dj", qf_toggle_focus, { desc = "Toggle focus: editor <-> diagnostics (quickfix)" })

-- Optional: same idea for LOCATION LIST (buffer-local diagnostics)
local function loc_toggle_focus()
	local lw = vim.fn.getloclist(0, { winid = 1 }).winid
	if lw == 0 then
		vim.cmd("lopen")
		lw = vim.fn.getloclist(0, { winid = 1 }).winid
	end
	if vim.api.nvim_get_current_win() == lw then
		vim.cmd("wincmd p")
	else
		vim.api.nvim_set_current_win(lw)
	end
end
vim.keymap.set("n", "<leader>dl", loc_toggle_focus, { desc = "Toggle focus: editor <-> location list" })

-- Handy extras
vim.keymap.set("n", "<leader>dx", "<cmd>cclose<cr>", { desc = "Close diagnostics (quickfix)" })
vim.keymap.set("n", "<leader>d]", "<cmd>cnext<cr>", { desc = "Next diagnostic (quickfix)" })
vim.keymap.set("n", "<leader>d[", "<cmd>cprev<cr>", { desc = "Prev diagnostic (quickfix)" })

-- Generic: swap to previous window (works anywhere)
vim.keymap.set("n", "<leader><tab>", "<C-w>p", { desc = "Previous window" })
