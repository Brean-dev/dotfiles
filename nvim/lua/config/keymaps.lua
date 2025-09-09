local harpoon = require("harpoon")

local tb = require("telescope.builtin")
harpoon:setup({})

-- basic telescope configuration
local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
	local file_paths = {}
	for _, item in ipairs(harpoon_files.items) do
		table.insert(file_paths, item.value)
	end

	require("telescope.pickers")
		.new({}, {
			prompt_title = "Harpoon",
			finder = require("telescope.finders").new_table({
				results = file_paths,
			}),
			previewer = conf.file_previewer({}),
			sorter = conf.generic_sorter({}),
		})
		:find()
end

vim.keymap.set("n", "<C-e>", function()
	toggle_telescope(harpoon:list())
end, { desc = "Open harpoon window" })

--vim.keymap.set("n", "<leader>ff", tb.find_files, { desc = "Files" })
vim.keymap.set("n", "<leader>ff", function()
	require("telescope.builtin").find_files({
		file_ignore_patterns = { "%.md$" },
	})
end, { desc = "Files (no .md)" })

vim.keymap.set("n", "<leader>fg", tb.live_grep, { desc = "Grep text" })
vim.keymap.set("n", "<leader>fs", tb.lsp_workspace_symbols, { desc = "Workspace symbols" })
vim.keymap.set("n", "<leader>fd", tb.lsp_document_symbols, { desc = "Document symbols" })
vim.keymap.set("n", "<leader>fb", tb.buffers, { desc = "Buffers" })
vim.keymap.set("n", "<leader>xd", function()
	require("telescope.builtin").diagnostics()
end, { desc = "Diagnostics (workspace)" })
vim.keymap.set("n", "<leader>gg", function()
	vim.cmd("LazyGit")
end, { desc = "Open LazyGit" })

vim.keymap.set("n", "<leader>?", "<cmd>Cheatsheet<CR>", { desc = "Open Cheatsheet" })
