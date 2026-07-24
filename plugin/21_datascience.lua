local now = MiniDeps.now
local now_if_args = Config.now_if_args
local later = MiniDeps.later
local add = Config.add
local nix = require('config.nix')

if not Config.isNixCats then
  local add = MiniDeps.add

  now(function()
    add({ source = "R-nvim/R.nvim" })
  end)

  now_if_args(function()
    add({ source = "jmbuhr/otter.nvim" })
  end)

  later(function()
    add({ source = "jpalardy/vim-slime" })
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
      pdfviewer = "",
      -- Use R.nvim's built-in rnvimserver-backed language server. Do not
      -- configure the external R languageserver through plugin/25_lsp.lua.
      r_ls = {
        completion = true,
        hover = true,
        signature = true,
        definition = true,
        references = true,
        implementation = true,
        document_symbol = true,
        workspace_symbol = true,
        document_highlight = true,
        rename = true,
      },
    })
  end
end)


-- Quarto
now(function()
  if nix.get_cat({ "r", "markdown" }, false) then
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
  end
end)

later(function()
  if nix.get_cat({ "r", "markdown" }, false) then
    require("quarto").setup({
      lspFeatures = {
        enabled = true,
        chunks = "curly",
        languages = { "r", "python", "julia" },
        diagnostics = {
          enabled = true,
          triggers = { "BufWritePost" },
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
  end
end)
