local now_if_args = Config.now_if_args

if not Config.isNixCats then
  local m_add = MiniDeps.add
  now_if_args(function()
    m_add("neovim/nvim-lspconfig")
  end)
end

now_if_args(function()
  -- R.nvim owns the R `r_ls` client and starts its bundled rnvimserver from
  -- its own plugin directory. Keep R out of this generic server registry.
  local servers = {
    basedpyright = {},
    ruff = {},
    marksman = {
      filetypes = { "markdown", "markdown_inline", "codecompanion" },
    },
    julials = {
      settings = {
        julia = {
          format = {
            indent = 2,
          },
          lsp = {
            autoStart = true,
            provideFormatter = true,
          },
        },
      },
    },
    lua_ls = {
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
          runtime = {
            version = "LuaJIT",
          },
          diagnostics = {
            disable = { "trailing-space" },
            globals = { "vim" },
          },
          workspace = {
            checkThirdParty = false,
          },
          doc = {
            privateName = { "^_" },
          },
          telemetry = {
            enable = false,
          },
        },
      },
    },
  }

  local lsp_flags = {
    allow_incremental_sync = true,
  }

  if vim.fn.has("nvim-0.11") == 1 then
    -- Neovim 0.11+ Native LSP Configuration
    for name, config in pairs(servers) do
      vim.lsp.config(name, config)
    end
    vim.lsp.config('*', { flags = lsp_flags })
    
    -- Enable all defined servers
    vim.lsp.enable(vim.tbl_keys(servers))
  else
    -- Fallback for Neovim < 0.11 (using nvim-lspconfig)
    local lspconfig = require('lspconfig')
    for name, config in pairs(servers) do
      local final_config = vim.tbl_extend("force", { flags = lsp_flags }, config)
      lspconfig[name].setup(final_config)
    end
  end
end)
