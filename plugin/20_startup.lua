local now = MiniDeps.now
local later = MiniDeps.later
local now_if_args = Config.now_if_args
local nix = require('config.nix')

if not Config.isNixCats then
  local add = MiniDeps.add
  now_if_args(function()
    add({
      source = "nvim-treesitter/nvim-treesitter",
      checkout = "master",
      monitor = "main",
      hooks = {
        post_checkout = function()
          vim.cmd("TSUpdate")
        end,
      },
    })
    add({
      source = "nvim-treesitter/nvim-treesitter-textobjects",
      checkout = "main",
    })
    add({ source = "zk-org/zk-nvim" })
  end)
end

-- Mini.nvim
now(function()
  local colorschemeName = nix.get_setting("onedark_dark", "colorscheme")
  if colorschemeName == 'light' then
    local palette = require('mini.hues').make_palette({
      background = '#fefcf5',
      foreground = '#657b83',
      accent = 'bg',
      saturation = 'high',
      n_hues = 8
    })
    palette.fg_mid2 = "#586e75"
    palette.fg_mid = "#073642"
    palette.bg_edge = "#fdf6e3"
    palette.accent_bg = "#eee8d5"
    require('mini.hues').apply_palette(palette)
  else
    if colorschemeName == "cyberdream" and vim.o.background == 'light' then
      colorschemeName = colorschemeName .. '-light'
    end
    vim.cmd.colorscheme(colorschemeName)
  end
end)

now(function()
  require("mini.basics").setup({
    options = {
      basic = true,
      extra_ui = true
    },
    mappings = {
      -- jk linewise, gy/gp system clipboard, gV select last change/yank
      basic = true,
      -- <C-hjkl> move between windows, <C-arrow> resize
      windows = true,
      move_with_alt = true,
      option_toggle_prefix = "<leader>u"
    },
    autocommands = {
      basic = true,
      relnum_in_visual_mode = true
    },
  })
end)

now(function()
  require("mini.icons").setup({
    use_file_extension = function(ext, _)
      local suf3, suf4 = ext:sub(-3), ext:sub(-4)
      return suf3 ~= "scm" and suf3 ~= "txt" and suf3 ~= "yml" and suf4 ~= "json" and suf4 ~= "yaml"
    end,
  })
  later(MiniIcons.mock_nvim_web_devicons)
  later(MiniIcons.tweak_lsp_kind)
end)

now(function()
  local predicate = function(notif)
    if not (notif.data.source == "lsp_progress" and notif.data.client_name == "lua_ls") then
      return true
    end
    -- Filter out some LSP progress notifications from 'lua_ls'
    return notif.msg:find("Diagnosing") == nil and notif.msg:find("semantic tokens") == nil
  end
  local custom_sort = function(notif_arr)
    return MiniNotify.default_sort(vim.tbl_filter(predicate, notif_arr))
  end

  require("mini.notify").setup({ content = { sort = custom_sort } })
  vim.notify = MiniNotify.make_notify()
end)

now(function()
  require("mini.sessions").setup()
end)

now(function()
  local starter = require("mini.starter")
  starter.setup({
    evaluate_single = true,
    items = {
      starter.sections.recent_files(5, true),
      function()
        local section = Config.startup.get_recent_files_by_ft_or_ext({
          "r",
          "sql",
          "julia",
          "python",
          "lua",
        })
        return section
      end,
      starter.sections.pick(),
      starter.sections.sessions(5, true),
      starter.sections.builtin_actions(),
      starter.sections.recent_files(3, false),
    },
    footer = Config.startup.footer_text,
    content_hooks = {
      starter.gen_hook.adding_bullet(),
      starter.gen_hook.indexing(
        "all",
        { "Builtin actions", "Recent files (current directory)", "Recent files", }
      ),
      starter.gen_hook.aligning("center", "center"),
      starter.gen_hook.padding(3, 2),
    },
  })
end)

now(function()
  require("mini.statusline").setup()
end)

now(function()
  require("mini.tabline").setup()
end)

now(function()
  local miniclue = require("mini.clue")
  --stylua: ignore
  miniclue.setup({
    window = {
      config = {
        width = 'auto'
      },
      delay = 100,
    },
    clues = {
      Config.leader_group_clues,
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.windows({ submode_resize = true, submode_move = true }),
      miniclue.gen_clues.z(),
    },
    triggers = {
      { mode = 'n', keys = '<Leader>' },      -- Leader triggers
      { mode = 'n', keys = '<LocalLeader>' }, -- LocalLeader triggers
      { mode = 'x', keys = '<Leader>' },
      { mode = 'x', keys = '<LocalLeader>' },
      { mode = 'n', keys = [[\]] }, -- mini.basics
      { mode = 'n', keys = '[' },   -- mini.bracketed
      { mode = 'n', keys = ']' },
      { mode = 'x', keys = '[' },
      { mode = 'x', keys = ']' },
      { mode = 'i', keys = '<C-x>' }, -- Built-in completion
      { mode = 'n', keys = 'g' },     -- `g` key
      { mode = 'x', keys = 'g' },
      { mode = 'n', keys = '`' },
      { mode = 'x', keys = '`' },
      { mode = 'n', keys = '"' }, -- Registers
      { mode = 'x', keys = '"' },
      { mode = 'i', keys = '<C-r>' },
      { mode = 'c', keys = '<C-r>' },
      { mode = 'n', keys = '<C-w>' }, -- Window commands
      { mode = 'n', keys = 'z' },     -- `z` key
      { mode = 'x', keys = 'z' },
    },
  })
end)

-- Treesitter

now_if_args(function()
  vim.treesitter.language.register("markdown", { "markdown", "codecompanion", "rmd", "quarto" })

  require 'treesitter-context'.setup {
    enable = true,
    multiwindow = false,      -- Enable multiwindow support.
    max_lines = 30,           -- How many lines the window should span. Values <= 0 mean no limit.
    min_window_height = 70,   -- Minimum editor window height to enable context. Values <= 0 mean no limit.
    line_numbers = true,
    multiline_threshold = 10, -- Maximum number of lines to show for a single context
    trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'
    -- Separator between context and content. Should be a single character string, like '-'.
    -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
    separator = '-',
    zindex = 20,     -- The Z-index of the context window
    on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
  }


  local ok_configs, configs = pcall(require, "nvim-treesitter.configs")

  if ok_configs and configs.setup then
    local opts = {
      highlight = { enable = true },
      indent = { enable = false },
      textobjects = {
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]a"] = "@parameter.inner", -- fixed typo
            ["]f"] = "@function.outer",
            ["]o"] = "@loop.*",
            ["]s"] = { query = "@local.scope", desc = "Next scope" },
            ["]z"] = { query = "@fold", desc = "Next fold" },
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer",
          },
          goto_previous_start = {
            ["[a"] = "@parameter.inner",
            ["[f"] = "@function.outer",
            ["[o"] = "@loop.*",
            ["[s"] = { query = "@local.scope", query_group = "locals", desc = "Prev. scope" },
            ["[z"] = { query = "@fold", query_group = "folds", desc = "Prev. fold" },
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer",
          },
          goto_next = {
            ["]e"] = "@conditional.outer",
          },
          goto_previous = {
            ["[e"] = "@conditional.outer",
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>x"] = "@parameter.inner",
          },
          swap_previous = {
            ["<leader>X"] = "@parameter.inner",
          },
        },
        lsp_interop = {
          enable = true,
          border = "none",
          floating_preview_opts = {},
          peek_definition_code = {
            ["<leader>lm"] = "@function.outer",
            ["<leader>lM"] = "@class.outer",
          },
        },
      },
    }


    -- Manual parser check for non-Nix users
    if not Config.isNixCats then
      local installed_check = function(lang)
        return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
      end
      local to_install = vim.tbl_filter(installed_check, opts.ensure_installed)
      if #to_install > 0 then
        require("nvim-treesitter").install(to_install)
      end
    end
    -- Environment-specific Overrides
    if not Config.isNixCats then
      opts.auto_install = true
      opts.ensure_installed = Config.treesitter_helpers.default_parsers
    else
      opts.auto_install = false
      -- Nix handles installation, so ensure_installed is skipped/empty
    end


    configs.setup(opts)
    return
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function(args)
      -- Use explicit buffer + filetype to avoid any ambiguity
      local ok = pcall(vim.treesitter.start, args.buf, args.match)
      vim.bo.syntax = 'on'
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo[0][0].foldmethod = 'expr'
    end,
  })

  -- Textobjects: require plugin and bail out quietly if missing
  local ok_nto, nto = pcall(require, "nvim-treesitter-textobjects")
  if not ok_nto then
    return
  end

  vim.g.no_plugin_maps = true
  nto.setup({
    move = {
      set_jumps = true,
    },
  })

  local move = require("nvim-treesitter-textobjects.move")
  local swap = require("nvim-treesitter-textobjects.swap")

  -- Map motion function names to actual functions
  local move_fns = {
    goto_next_start     = move.goto_next_start,
    goto_next_end       = move.goto_next_end,
    goto_previous_start = move.goto_previous_start,
    goto_previous_end   = move.goto_previous_end,
    goto_next           = move.goto_next,
    goto_previous       = move.goto_previous,
  }

  -- All motions defined in one place
  -- spec = { query_or_list, query_group, desc }
  local move_maps = {
    goto_next_start = {
      ["]a"] = { "@parameter.inner", "textobjects", "Next parameter" },
      ["]f"] = { "@function.outer", "textobjects", "Next function start" },
      ["]o"] = { { "@loop.inner", "@loop.outer" }, "textobjects", "Next loop" },
      ["]s"] = { "@local.scope", "locals", "Next scope" },
      ["]z"] = { "@fold", "folds", "Next fold" },
    },
    goto_next_end = {
      ["]M"] = { "@function.outer", "textobjects", "Next function end" },
      ["]["] = { "@class.outer", "textobjects", "Next class end" },
    },
    goto_previous_start = {
      ["[a"] = { "@parameter.inner", "textobjects", "Previous parameter" },
      ["[f"] = { "@function.outer", "textobjects", "Previous function start" },
      ["[o"] = { { "@loop.inner", "@loop.outer" }, "textobjects", "Previous loop" },
      ["[s"] = { "@local.scope", "locals", "Previous scope" },
      ["[z"] = { "@fold", "folds", "Previous fold" },
    },
    goto_previous_end = {
      ["[M"] = { "@function.outer", "textobjects", "Previous function end" },
      ["[]"] = { "@class.outer", "textobjects", "Previous class end" },
    },
    goto_next = {
      ["]e"] = { "@conditional.outer", "textobjects", "Next conditional" },
    },
    goto_previous = {
      ["[e"] = { "@conditional.outer", "textobjects", "Previous conditional" },
    },
  }

  -- Generate motion keymaps
  for fn_name, maps in pairs(move_maps) do
    local fn = move_fns[fn_name]
    if fn then
      for lhs, spec in pairs(maps) do
        local query_or_list, group, desc = spec[1], spec[2], spec[3]
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          fn(query_or_list, group)
        end, { desc = desc })
      end
    end
  end

  -- Swap keymaps (unchanged, but minimal)
  vim.keymap.set("n", "<leader>x", function()
    swap.swap_next("@parameter.inner")
  end, { desc = "Swap with next parameter" })

  vim.keymap.set("n", "<leader>X", function()
    swap.swap_previous("@parameter.inner")
  end, { desc = "Swap with previous parameter" })
end)

-- zk
now_if_args(function()
  require("zk").setup({
    picker = "minipick",
    lsp = {
      -- `config` is passed to `vim.lsp.start_client(config)`
      config = {
        cmd = { "zk", "lsp" },
        name = "zk",
        -- on_attach = ...
        -- etc, see `:h vim.lsp.start_client()`
      },

      -- automatically attach buffers in a zk notebook that match the given filetypes
      auto_attach = {
        enabled = true,
        filetypes = { "markdown" },
      },

    },
  })
end)
