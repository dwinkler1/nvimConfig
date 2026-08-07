local Config = require('config')
local add = Config.add
local later = MiniDeps.later
local now = MiniDeps.now
local now_if_args = Config.now_if_args

-- Plugin sources configuration
local PLUGIN_SOURCES = {
  "hrsh7th/cmp-cmdline",
  "xzbdmw/colorful-menu.nvim",
  "zbirenbaum/copilot.lua",
  "jmbuhr/cmp-pandoc-references",
  "fang2hou/blink-copilot",
  "nickjvandyke/opencode.nvim",
}

local PLUGIN_ADDS = {
  "cmp-cmdline",
  "blink.compat",
  "colorful-menu.nvim",
  "cmp-pandoc-references",
}

local function get_mini_icons_highlight(ctx)
  local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
  return hl
end

local function get_blink_fuzzy_setting()
  return {
    sorts = { "exact", "score", "sort_text" },
    use_proximity = true,
  }
end

-- Plugin loading
if not Config.isNixCats then
  local add = MiniDeps.add

  now_if_args(function()
    add({
      source = "saghen/blink.cmp",
      depends = { "rafamadriz/friendly-snippets" },
    })
  end)

  later(function()
    for _, source in ipairs(PLUGIN_SOURCES) do
      add({ source = source })
    end
  end)
end

-- Batch add simple plugins
later(function()
  for _, plugin in ipairs(PLUGIN_ADDS) do
    add(plugin)
  end
end)

-- Configure plugins with setup
later(function()
  add("copilot.lua")
  require("copilot").setup({
    suggestion = { enabled = false },
    panel = { enabled = false },
    filetypes = {
      help = true,
      julia = true,
      lua = true,
      markdown = true,
      nix = true,
      python = true,
      r = true,
      sh = function()
        if string.match(vim.fs.basename(vim.api.nvim_buf_get_name(0)), '^%.env.*') then
          -- disable for .env files
          return false
        end
        return true
      end,
      ["."] = false
    },
    server_opts_overrides = {
      settings = {
        telemetry = { telemetryLevel = 'off' }
      }
    },
    should_attach = function(_, bufname)
      if string.match(bufname, "env") then
        return false
      end
      return true
    end
  })
end)

later(function()
  add("blink-copilot")
  require("blink-copilot").setup({
    max_completions = 1,
  })
end)

later(function()
  vim.g.opencode_opts = {
    events = {
      reload = true,
      permissions = {
        enabled = true,
        edits = { enabled = true },
      },
    },
    server = {
      start = function()
        vim.cmd("vsplit term://opencode --port")
        vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
        vim.cmd("wincmd p")
      end
    },
  }
  add("opencode.nvim")
end)

now_if_args(function()
  add("blink.cmp")

  require("blink.cmp").setup({
    -- Direct blink keymaps (C-space/C-l).
    -- Tab/Enter/Up/Down are handled via multistep chains in 23_editor.lua,
    -- which chain blink_next/blink_prev/blink_accept with other editor actions.
    keymap = {
      preset = "default",
      ["<C-space>"] = { "show", "select_next" },
      ["<C-l>"] = { "accept" },
    },
    cmdline = {
      enabled = true,
      keymap = {
        preset = "inherit",
        ["<Tab>"] = { "show", "select_next" },
        ["<S-Tab>"] = { "show", "select_prev" },
        ["<C-l>"] = { "accept" },
      },
      completion = {
        menu = { auto_show = true },
        list = {
          selection = { preselect = false, auto_insert = true }
        },
      },
      sources = function()
        local cmd_type = vim.fn.getcmdtype()
        if cmd_type == "/" or cmd_type == "?" then
          return { "buffer" }
        elseif cmd_type == ":" or cmd_type == "@" then
          return { "cmdline", "cmp_cmdline" }
        end
        return {}
      end,
    },
    fuzzy = get_blink_fuzzy_setting(),
    signature = {
      enabled = true,
      window = { show_documentation = true }
    },
    completion = {
      menu = {
        border = "rounded",
        draw = {
          treesitter = { "lsp" },
          components = {
            label = {
              text = function(ctx)
                return require("colorful-menu").blink_components_text(ctx)
              end,
              highlight = function(ctx)
                return require("colorful-menu").blink_components_highlight(ctx)
              end,
            },
            kind_icon = { highlight = get_mini_icons_highlight },
            kind = { highlight = get_mini_icons_highlight },
          },
        },
      },
      list = {
        selection = { preselect = false, auto_insert = true }
      },
      ghost_text = { enabled = true, show_with_menu = true },
      documentation = { auto_show = true, window = { border = "rounded" } },
      trigger = { show_in_snippet = false },
    },
    snippets = { preset = "mini_snippets" },
    sources = {
      default = { "references", "lsp", "path", "snippets", "buffer", "omni", "copilot" },
      providers = {
        path = {
          score_offset = 50,
          opts = {
            get_cwd = function(_)
              return vim.fn.getcwd()
            end,
          },
        },
        lsp = { score_offset = 40 },
        snippets = { score_offset = 0 },
        cmp_cmdline = {
          name = "cmp_cmdline",
          module = "blink.compat.source",
          enabled = false,
          score_offset = 10,
          opts = { cmp_name = "cmdline" }
        },
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 45,
          async = true,
        },
        references = {
          name = "pandoc_references",
          module = "cmp-pandoc-references.blink",
          score_offset = 50,
        },
      },
    },
  })
end)
