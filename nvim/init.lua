vim.tbl_islist = vim.islist
vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim3/bin/python")

vim.o.wrap = true

vim.o.linebreak = true
vim.o.breakindent = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
-- leader key
vim.g.mapleader = " "

-- load plugins
require("plugins")
require("config.telescope")
-- require("config.gruv")
require("config.mintheme")

require("config.diagnostic")
require("config.format")
require("config.cmp")
require("config.lsp")
require("config.keymaps")
require("config.lualine")
require("config.luxmotion")
