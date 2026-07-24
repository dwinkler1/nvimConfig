local add = Config.add
local now_if_args = Config.now_if_args
local later = MiniDeps.later
local nix = require('config.nix')

if not Config.isNixCats then
  local add = MiniDeps.add
  later(function()
    add({ source = "Bilal2453/luvit-meta" })
    add({ source = "folke/lazydev.nvim" })
  end)
end

-- lua
later(function()
  if nix.get_cat("lua", false) then
    add("luvit-meta")
    add("lazydev")
    require("lazydev").setup({
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        "lua",
        "mini.nvim",
        "MiniDeps",
        { path = "luvit-meta/library", words = { "vim%.uv" } },
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    })
  end
end)

-- Markdown
now_if_args(function()
  add("render-markdown.nvim")
  require('render-markdown').setup({
    --    completions = { blink = { enabled = true } },
    file_types = { 'markdown', 'codecompanion', },
    link = {
      wiki = {
        body = function(ctx)
          local diagnostics = vim.diagnostic.get(ctx.buf, {
            lnum = ctx.row,
            severity = vim.diagnostic.severity.HINT,
          })
          for _, diagnostic in ipairs(diagnostics) do
            if diagnostic.source == 'marksman' then
              return diagnostic.message
            end
          end
          return nil
        end,
      },
    },
  })
end)
