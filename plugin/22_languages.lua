local add = Config.add
local now_if_args = Config.now_if_args
local later = MiniDeps.later

if not Config.isNixCats then
  local m_add = MiniDeps.add
  later(function()
    m_add({ source = "Bilal2453/luvit-meta" })
    m_add({ source = "folke/lazydev.nvim" })
  end)
end

-- lua
later(function()
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
end)

-- Markdown
now_if_args(function()
  add("render-markdown.nvim")
  require('render-markdown').setup({
    --    completions = { blink = { enabled = true } },
    file_types = { 'markdown', 'quarto', 'rmd', 'codecompanion', },
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
