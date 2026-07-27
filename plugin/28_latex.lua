-- vimtex integration for raw .tex workflows (paper drafts, AEA submissions,
-- beamer slides). Rides in the `markdown` cat because Quarto users routinely
-- also write standalone .tex.

local Config = require('config')
local later = MiniDeps.later
local nix = require('config.nix')

later(function()
  if not nix.get_cat("markdown", false) then
    return
  end

  Config.add("vimtex")

  local ok, vimtex = pcall(require, "vimtex")
  if not ok then
    vim.notify("vimtex not available", vim.log.levels.WARN)
    return
  end

  -- Keep conservative defaults: latexmk continuous compilation off, single
  -- viewer (zathura falls back to Evince on most setups).
  vimtex.setup({
    enabled = true,
    compile_on_save = false,
    compiler = "latexmk",
    -- Avoid hooking spell/formatting into our global <leader> group;
    -- vimtex stashes its own <localleader> mappings automatically.
  })

  -- Filetype detection is normally on, but force it explicitly so .tex files
  -- opened outside Quarto still pick up the LSP + viewer hooks.
  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = { "*.tex", "*.sty", "*.cls" },
    callback = function(args)
      local buf = args.buf
      if vim.api.nvim_buf_is_loaded(buf) then
        vim.bo[buf].filetype = "tex"
      end
    end,
  })
end)
