return {
	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,
		config = function()
			require("tiny-inline-diagnostic").setup({
				preset = "modern",
				options = {
					add_messages = { messages = true },
					show_code = true,
					throttle = 20,
				},
			})
			vim.diagnostic.config({ virtual_text = false }) -- Disable built-in virtual text
		end,
	},
}
