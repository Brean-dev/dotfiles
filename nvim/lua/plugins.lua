local fn = vim.fn

-- Bootstrap packer if not installed
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
	vim.cmd("packadd packer.nvim")
end

-- Reload Neovim and sync plugins when this file is written
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup END
]])

-- Plugin list
return require("packer").startup(function(use)
	use("wbthomason/packer.nvim") -- packer manages itself

	-- essentials
	use("nvim-lua/plenary.nvim")

	-- Better syntax highlighting with Tree-sitter (including Go)
	use({
		"nvim-treesitter/nvim-treesitter",
		run = function()
			local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
			ts_update()
		end,
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "go", "gomod", "gosum", "gowork", "lua", "vim", "vimdoc", "query" },
				sync_install = false,
				auto_install = true,
				ignore_install = {},
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				indent = { enable = true },
				modules = {},
			})
		end,
	})

	-- Optional: show current function/struct context
	use({ "nvim-treesitter/nvim-treesitter-context", after = "nvim-treesitter" })

	-- Optional: colored bracket pairs

	-- fuzzy finder
	use({ "romgrk/fzy-lua-native", run = "make" })
	use({
		"nvim-telescope/telescope-fzf-native.nvim",
		run = "make",
		cond = vim.fn.executable("make") == 1,
	})

	-- icons (optional but nice)
	use({ "nvim-tree/nvim-web-devicons" })

	-- harpoon
	use({
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		requires = { "nvim-lua/plenary.nvim" },
	})

    use({
  "neovim/nvim-lspconfig",
  requires = {
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },
  },
  config = function()
    -- Mason manages binaries; auto-install missing servers
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "gopls" },
      automatic_installation = true,
    })

    -- Capabilities (nvim-cmp if present)
    local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = ok_cmp and cmp_lsp.default_capabilities()
      or vim.lsp.protocol.make_client_capabilities()

    -- Define the server config with the new core API
    vim.lsp.config("gopls", {
      capabilities = capabilities,
      settings = {
        gopls = {
          analyses = { unusedparams = true, shadow = true },
          staticcheck = true,
        },
      },
    })

    -- Enable the server if the binary is available
    if vim.fn.executable("gopls") == 1 then
      vim.lsp.enable({ "gopls" })
    end

    -- Optional: tweak LSP semantic token highlight links for Go
    vim.cmd([[
      hi! link @lsp.type.parameter.go Identifier
      hi! link @lsp.type.function.go Function
      hi! link @lsp.type.method.go Function
      hi! link @lsp.type.interface.go Type
      hi! link @lsp.typemod.variable.global.go Constant
    ]])
  end,
})

	use("hrsh7th/nvim-cmp")
	use("hrsh7th/cmp-nvim-lsp")
	use("L3MON4D3/LuaSnip")
	use("saadparwaiz1/cmp_luasnip")

	-- formatting
	use({
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup()
		end,
	})
	use({
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufNewFile" }, -- lazy-load on file open
		config = function()
			local lint = require("lint")

			-- Optional: define linters per filetype
			-- lint.linters_by_ft = { lua = { 'luacheck' }, javascript = { 'eslint' } }

			local grp = vim.api.nvim_create_augroup("nvim_lint", { clear = true })
			vim.api.nvim_create_autocmd("BufWritePost", {
				group = grp,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	})

	-- colorscheme
 use({ "ellisonleao/gruvbox.nvim" })
	use({ "datsfilipe/min-theme.nvim" })
	-- wilder (make sure you have lua/config/wilder.lua)
	use({
		"gelguy/wilder.nvim",
		config = function()
			require("config.wilder")
		end,
	})
	use({
		"nvim-lualine/lualine.nvim",
		requires = { "nvim-tree/nvim-web-devicons", opt = true },
	})
	use({
		"kdheepak/lazygit.nvim",
		requires = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("telescope").load_extension("lazygit")
		end,
	})
	use({
		"nvim-telescope/telescope.nvim",
		requires = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({})
		end,
	})
	use({
		"Brean-dev/cheatsheet.nvim",
		requires = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/popup.nvim",
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("cheatsheet").setup({
				bundled_cheatsheets = true,
				bundled_plugin_cheatsheets = true,
				include_only_installed_plugins = true,
				telescope_mappings = {
					["<CR>"] = require("cheatsheet.telescope.actions").select_or_fill_commandline,
					["<A-CR>"] = require("cheatsheet.telescope.actions").select_or_execute,
					["<C-Y>"] = require("cheatsheet.telescope.actions").copy_cheat_value,
					["<C-E>"] = require("cheatsheet.telescope.actions").edit_user_cheatsheet,
				},
			})
		end,
	})
	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})
	use({
		"LuxVim/nvim-luxmotion",
		config = function()
			require("luxmotion").setup()
		end,
	})
	use({
		"y3owk1n/undo-glow.nvim",
		config = function()
			require("config.undo_glow")
		end,
	})
end)
