-- ~/.config/nvim/lua/config/diagnostics.lua
-- Neovim 0.12-ready diagnostics:
-- - NO sign_define (deprecated)
-- - Multi-line diagnostics via virtual_lines (proper wrapping)
-- - Wrapped floats
-- - Clean, per-severity icons

-- Per-severity gutter icons
local icons = {
	[vim.diagnostic.severity.ERROR] = "",
	[vim.diagnostic.severity.WARN] = "",
	[vim.diagnostic.severity.HINT] = "",
	[vim.diagnostic.severity.INFO] = "",
}

vim.diagnostic.config({
	-- Signs in the gutter (modern way)
	signs = {
		text = icons,
	},

	-- Turn OFF virtual_text (single-line extmarks) to prevent overflow/clutter
	virtual_text = false,

	-- Turn ON virtual_lines for multi-line diagnostics that wrap naturally
	-- (available since 0.10). These render as real overlay rows below the line.
	virtual_lines = {
		only_current_line = false, -- set true if you want only the current line
		highlight_whole_line = false,
		spacing = 0,
		-- Per-diagnostic prefix; keep it short. You can indent here if you like.
		prefix = function(diag)
			return (icons[diag.severity] or "●") .. " "
		end,
	},

	underline = true,
	update_in_insert = false,
	severity_sort = true,

	float = {
		border = "rounded",
		source = "if_many",
	},
})

-- Wrapped float opener using modern option setter
local function open_diag_float_wrapped(opts)
	opts = opts or {}
	opts.border = opts.border or "rounded"
	opts.source = opts.source or "if_many"
	opts.focusable = false
	opts.max_width = opts.max_width or math.floor(vim.o.columns * 0.7)

	local before = vim.api.nvim_list_wins()
	vim.diagnostic.open_float(nil, opts)
	local after = vim.api.nvim_list_wins()

	local newwin
	do
		local seen = {}
		for _, w in ipairs(before) do
			seen[w] = true
		end
		for _, w in ipairs(after) do
			if not seen[w] then
				newwin = w
				break
			end
		end
	end

	if newwin and vim.api.nvim_win_is_valid(newwin) then
		local set = vim.api.nvim_set_option_value
		set("wrap", true, { win = newwin })
		set("linebreak", true, { win = newwin }) -- word boundaries
		set("breakindent", true, { win = newwin }) -- indent wrapped lines
		set("breakindentopt", "sbr", { win = newwin }) -- use showbreak string
		set("showbreak", "↳ ", { win = newwin }) -- marker for wrapped lines
	end
end

-- Auto-peek float (wrapped)
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
	callback = function()
		open_diag_float_wrapped({
			close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
		})
	end,
})

-- Mapping for on-demand float
vim.keymap.set("n", "<leader>e", function()
	open_diag_float_wrapped()
end, { desc = "Line diagnostics (wrapped)" })
