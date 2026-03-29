require("theprimeagen")

-- hello fem

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		pcall(vim.treesitter.start, buf)
	end,
})
