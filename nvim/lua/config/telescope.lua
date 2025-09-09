-- ~/.config/nvim/lua/config/telescope.lua
local ok_t, telescope = pcall(require, "telescope")
if not ok_t then return end
local ok_a, actions = pcall(require, "telescope.actions")
if not ok_a then return end

-- detect fd/fdfind (RHEL often has fdfind)
local fd_bin = (vim.fn.executable("fd") == 1 and "fd")
  or (vim.fn.executable("fdfind") == 1 and "fdfind")
  or nil

telescope.setup({
  defaults = {
    prompt_prefix = " ",
    selection_caret = " ",
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      },
    },
    vimgrep_arguments = {
      "rg","--no-heading","--with-filename","--line-number","--column",
      "--smart-case","--hidden","--glob","!.git/",
    },
    file_ignore_patterns = { ".git/", "node_modules/", "dist/", "build/" },
    layout_strategy = "flex",
  },
  pickers = {
    find_files = (fd_bin and {
      hidden = true,
      find_command = { fd_bin, "--type", "f", "--hidden", "--exclude", ".git" },
    }) or { hidden = true },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})
pcall(telescope.load_extension, "fzf")
