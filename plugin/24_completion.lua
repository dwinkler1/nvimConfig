local add = Config.add
local later = MiniDeps.later
local now = MiniDeps.now
local now_if_args = Config.now_if_args

-- Constants
local BLINK_VERSION = "v1.10.2"

-- Plugin sources configuration
local PLUGIN_SOURCES = {
  "hrsh7th/cmp-cmdline",
  "xzbdmw/colorful-menu.nvim",
  "zbirenbaum/copilot.lua",
  "jmbuhr/cmp-pandoc-references",
  "fang2hou/blink-copilot",
  "olimorris/codecompanion.nvim"
}

local PLUGIN_ADDS = {
  "cmp-cmdline",
  "blink.compat",
  "colorful-menu.nvim",
  "cmp-pandoc-references",
}

-- Helper functions
local function create_system_prompt(role_description)
  return function(context)
    local lang = context.filetype or "programmer"
    return "I want you to act as a senior " .. lang .. " developer. " .. role_description
  end
end

local function get_code_block(context)
  local text = require("codecompanion.helpers.code").get_code(context.start_line, context.end_line)
  return "```" .. context.filetype .. "\n" .. text .. "\n```"
end

local function get_mini_icons_highlight(ctx)
  local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
  return hl
end

local function get_blink_fuzzy_setting()
  local setting = {
    sorts = { "exact", "score", "sort_text" }
  }

  if not Config.isNixCats then
    setting.prebuilt_binaries = { force_version = BLINK_VERSION }
  end

  return setting
end

-- Plugin loading
if not Config.isNixCats then
  local add = MiniDeps.add

  now_if_args(function()
    add({
      source = "saghen/blink.cmp",
      depends = { "rafamadriz/friendly-snippets" },
      checkout = BLINK_VERSION,
    })
  end)

  later(function()
    for _, source in ipairs(PLUGIN_SOURCES) do
      add({ source = source })
    end
  end)
end

local function get_codecompanion_config()
  return {
    adapters = {
      acp = {
        -- Codex = heavy agent lane (ChatGPT Edu login via `codex login`; ~/.codex/auth.json).
        -- Requires `codex-acp` on PATH (~/.nix-profile/bin). ACP-only slash commands in the
        -- chat buffer: /resume (restore a past session, fresh chat only), /mode (switch agent
        -- mode), /command, /acp_session_options (e.g. model per session); `\` triggers ACP
        -- command completion (1-5s delay after chat open).
        codex = function()
          return require("codecompanion.adapters").extend("codex", {
            defaults = {
              auth_method = "chatgpt",
            },
          })
        end,
      },
    },
    interactions = {
      chat = {
        adapter = {
          name = "copilot",
          model = "claude-sonnet-5",
        },
        slash_commands = {
          ["share"] = {
            opts = {
              token = os.getenv("GITHUB_GIST_TOKEN"),
            },
          },
        },
        opts = {
          completion_provider = "blink",
          context_management = {
            editing = {
              trigger = 0.65,
              keep_cycles = 3,
              exclude_tools = { "memory" },
            },
            compaction = {
              trigger = 0.85,
              min_token_savings = 10000,
            },
          },
        },
      },
      inline = {
        adapter = {
          name = "copilot",
          model = "gpt-5-mini",
        },
      },
      shared = {
        keymaps = {
          accept_change = {
            modes = { n = "ga" },
            description = "Accept the suggested change",
          },
          reject_change = {
            modes = { n = "gr" },
            opts = { nowait = true },
            description = "Reject the suggested change",
          },
        },
      },
      background = {
        adapter = {
          name = "copilot",
          model = "gpt-5-mini",
        },
        chat = {
          callbacks = {
            ["on_ready"] = {
              actions = { "interactions.background.builtin.chat_make_title" },
              enabled = true,
            },
          },
          opts = {
            enabled = true,
          },
        },
      },
    },
    display = {
      chat = {
        show_settings = false,
        window = {
          layout = "horizontal",
          position = "bottom",
          height = 0.33,
        },
      },
      diff = {
        enabled = true,
        threshold_for_chat = 6,
      },
    },
    rules = {
      default = {
        description = "Collection of common files for all projects",
        files = {
          ".clinerules",
          ".cursorrules",
          ".rules",
          ".github/copilot-instructions.md",
          "AGENT.md",
          "AGENTS.md",
          { path = "CLAUDE.md", parser = "claude" },
          { path = "CLAUDE.local.md", parser = "claude" },
          { path = "~/.claude/CLAUDE.md", parser = "claude" },
        },
      },
      opts = {
        chat = {
          autoload = "default",
          enabled = true,
        },
      },
    },
    prompt_library = {
      ["expert"] = {
        interaction = "chat",
        description = "Get expert advice from an LLM",
        opts = { alias = "expert" },
        prompts = {
          {
            role = "system",
            content = create_system_prompt(
              "I will ask you specific questions and I want you to return concise explanations and codeblock examples."
            ),
          },
          {
            role = "user",
            content = function(context)
              return "I have the following code:\n\n" .. get_code_block(context) .. "\n\n"
            end,
            opts = { contains_code = true },
          },
        },
      },
      ["fixer"] = {
        interaction = "chat",
        description = "Fix code errors with expert guidance",
        opts = { alias = "fixer" },
        prompts = {
          {
            role = "system",
            content = create_system_prompt(
              "I have a block of code that is not working and will give you a hint about the error. I want you to return the corrected code and a concise explanation of the corrections."
            ),
          },
          {
            role = "user",
            content = function(context)
              return "The following code has an error:\n\n" .. get_code_block(context) .. "\n\nThe error is:"
            end,
            opts = { contains_code = true },
          },
        },
      },
      ["suggest"] = {
        interaction = "chat",
        description = "Suggest improvements to the buffer",
        opts = { alias = "suggest" },
        prompts = {
          {
            role = "system",
            content = create_system_prompt(
              "When asked to improve code, follow these steps:\n" ..
              "1. Identify the programming language.\n" ..
              "2. Think separately for each function or significant block of code and think about possible improvements (e.g., for better readability or speed) in the context of the language.\n" ..
              "3. Think about the whole document and think about possible improvements.\n" ..
              "4. Provide the improved code.\n" ..
              "5. Provide a concise explanation of the improvements."
            ),
          },
          {
            role = "user",
            content = function(context)
              return "Please improve the following code:\n\n" .. get_code_block(context)
            end,
            opts = { contains_code = true },
          },
        },
      },
      ["agent"] = {
        interaction = "chat",
        description = "Agentic coding with the @{agent} tool group (read/edit/grep/run)",
        opts = { alias = "agent" },
        prompts = {
          {
            role = "user",
            content = function(context)
              return "@{agent} Work on the following code:\n\n" .. get_code_block(context) .. "\n\n"
            end,
            opts = { contains_code = true },
          },
        },
      },
      ["tdd"] = {
        interaction = "chat",
        description = "Workflow: plan the buffer change, implement it, run the tests",
        opts = { alias = "tdd", is_workflow = true },
        prompts = {
          {
            {
              role = "user",
              content = function(context)
                return "Let's work test-driven. First, study #buffer and the relevant parts of the codebase, then propose a concise implementation plan (no code yet).\n\nThe code under discussion:\n\n"
                  .. get_code_block(context)
                  .. "\n\nThe task: "
              end,
              opts = { contains_code = true },
            },
          },
          {
            {
              role = "user",
              content = "Implement the plan now, writing or updating tests alongside the code. @{agent}",
              opts = { auto_submit = true },
            },
          },
          {
            {
              role = "user",
              content = "Run the project's test suite with @{run_command} and fix any failures until it passes.",
              opts = { auto_submit = true },
            },
          },
        },
      },
    },
  }
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


-- CodeCompanion habit notes (chat buffer unless stated):
--   /compact  compact history, keep summary        /fork    fork the conversation
--   /symbols  insert symbols for a file            /share   export chat to a GitHub gist
--   gm        toggle "btw" ephemeral message       gty      YOLO: approve all tool calls
--   gba/gbd   buffer sync add/drop                 gd       debug window (adapter/tools info)
--   Codex (ACP) lane: /resume (fresh chat only), /mode, /command, /acp_session_options,
--   `\` ACP command completion. Prompt library: /expert /fixer /suggest /agent /tdd (workflow).
later(function()
  add("codecompanion.nvim")

  -- now use function
  require("codecompanion").setup(get_codecompanion_config())
  vim.cmd([[cab cc CodeCompanion]])
end)

now_if_args(function()
  add("blink.cmp")

  require("blink.cmp").setup({
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
      documentation = { auto_show = true },
      trigger = { show_in_snippet = false },
    },
    snippets = { preset = "mini_snippets" },
    sources = {
      per_filetype = {
        codecompanion = { "codecompanion" },
      },
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
        codecompanion = {
          name = "CodeCompanion",
          module = "codecompanion.providers.completion.blink",
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
