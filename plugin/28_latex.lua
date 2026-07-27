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

  -- vimtex is a VimL plugin: it does not expose a Lua module.  Configure it
  -- via globals before loading so the plugin picks them up on startup.
  vim.g.vimtex_compiler_method = "latexmk"
  vim.g.vimtex_compiler_latexmk = {
    -- Keep conservative defaults: no continuous background compilation and no
    -- callback chatter.  Manual :VimtexCompile still works on demand.
    continuous = 0,
    callback = 0,
  }
  -- Let vimtex choose the first available viewer (zathura, Skim, Evince, ...).

  Config.add("vimtex")

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
