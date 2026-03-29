require("luxmotion").setup({
	cursor = {
		duration = 800, -- Cursor animation duration (ms)
		easing = "ease-out", -- Cursor easing function
		enabled = true,
	},
	scroll = {
		duration = 1000, -- Scroll animation duration (ms)
		easing = "ease-out", -- Scroll easing function
		enabled = true,
	},
	performance = {
		enabled = false, -- Enable performance mode
	},
	keymaps = {
		cursor = true, -- Enable cursor motion keymaps
		scroll = true, -- Enable scroll motion keymaps
	},
})
