local now = MiniDeps.now
local now_if_args = Config.now_if_args
local later = MiniDeps.later
local add = Config.add
local nix = require('config.nix')

if not Config.isNixCats then
  local m_add = MiniDeps.add

  now(function()
    m_add({ source = "R-nvim/R.nvim" })
  end)

  now_if_args(function()
    m_add({ source = "jmbuhr/otter.nvim" })
  end)

  later(function()
    m_add({ source = "jpalardy/vim-slime" })
  end)
end

-- terminal
later(function()
  vim.g.slime_target = "neovim"
  vim.g.slime_no_mappings = true
  add("vim-slime")
  vim.g.slime_cell_delimiter = vim.g.slime_cell_delimiter or "# %%"
  vim.g.slime_bracketed_paste = Config.opt_bracket
  vim.g.slime_input_pid = false
  vim.g.slime_suggest_default = true
  vim.g.slime_menu_config = false
  vim.g.slime_neovim_ignore_unlisted = false

  -- Define standard slime mappings
  vim.keymap.set("v", "<CR>", "<Plug>SlimeRegionSend", { noremap = true })
  vim.keymap.set("v", "<localleader><localleader>", "<Plug>SlimeRegionSend", { noremap = true })
  vim.keymap.set("n", "<localleader><localleader>", "<Plug>SlimeLineSend", { noremap = true })
  -- Standardize on C-c C-c as well (common convention)
  vim.keymap.set("v", "<C-c><C-c>", "<Plug>SlimeRegionSend", { noremap = true })
  vim.keymap.set("n", "<C-c><C-c>", "<Plug>SlimeParagraphSend", { noremap = true })
end)

-- r
now(function()
  if nix.get_cat("r", false) then
    vim.g.rout_follow_colorscheme = true
    require("r").setup({
      -- Create a table with the options to be passed to setup()
      R_args = { "--quiet", "--no-save" },
      auto_start = "no",
      objbr_auto_start = false,
      objbr_place = 'console,below',
      rconsole_width = 120,
      min_editor_width = 80,
      rconsole_height = 20,
      nvimpager = "split_h",
      pdfviewer = "zathura",
    })
  end
end)


-- Quarto
now(function()
  vim.treesitter.language.register("markdown", { "quarto", "rmd" })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "quarto" },
    callback = function()
      require("otter").activate()
    end,
  })

  require("otter").setup({
    lsp = {
      diagnostic_update_events = { "BufWritePost", "InsertLeave" },
    },
    buffers = {
      set_filetype = true,
      write_to_disk = true,
    },
  })
end)

later(function()
  require("quarto").setup({
    lspFeatures = {
      enabled = true,
      languages = { "r", "python", "julia" },
      diagnostics = {
        enabled = true,
        triggers = { "BufWrite" },
      },
      completion = {
        enabled = true,
      },
    },
    codeRunner = {
      enabled = true,
      default_method = "slime",
    },
  })
end)
