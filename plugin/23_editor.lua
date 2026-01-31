local later = MiniDeps.later
local add = Config.add

if not Config.isNixCats then
  local m_add = MiniDeps.add

  later(function()
    m_add("stevearc/conform.nvim")
  end)
end

-- Formatting
later(function()
  add("conform.nvim")
  require("conform").setup({
    -- Map of filetype to formatters
    formatters_by_ft = {
      javascript = { "prettier" },
      json = { "prettier" },
      python = { "ruff_format", "ruff_organize_imports" },
      nix = { "alejandra" },
      -- r = { "my_styler" },
      rmd = { "injected" },
      quarto = { "injected" },
    },

    lsp_format = "fallback",

    formatters = {
      my_styler = {
        command = "R",
        -- A list of strings, or a function that returns a list of strings
        -- Return a single string instead of a list to run the command in a shell
        args = { "-s", "-e", "styler::style_file(commandArgs(TRUE)[1])", "--args", "$FILENAME" },
        stdin = false,
      },
    },
  })
end)

-- Edit
later(function()
  local ai = require("mini.ai")
  local spec_treesitter = ai.gen_spec.treesitter
  ai.setup({
    search_method = "cover",
    n_lines = 1000,
  })
end)

later(function()
  require("mini.align").setup()
end)

later(function()
  require("mini.animate").setup({ scroll = { enable = false } })
end)

later(function()
  require("mini.bracketed").setup({
    diagnostic = {
      options = {
        float = false,
      },
    },
  })
end)

later(function()
  require("mini.bufremove").setup()
end)

later(function()
  require("mini.comment").setup()
end)

later(function()
  require("mini.cursorword").setup({ delay = 1000 })
end)

later(function()
  require("mini.diff").setup({
    view = {
      style = "sign",
    },
    mappings = {
      apply = "<leader>ga",
      reset = "<leader>gr",
      textobject = "o",
    },
    options = {
      linematch = 1000,
      algorithm = 'myers',
    },
  })
end)

later(function()
  require("mini.files").setup({
    windows = {
      preview = true,
      width_focus = 80,
      width_preview = 90,
    },
    mappings = {
      mark_goto = "'",
      synchronize = ':',
    }
  })
  local minifiles_augroup = vim.api.nvim_create_augroup("ec-mini-files", {})
  vim.api.nvim_create_autocmd("User", {
    group = minifiles_augroup,
    pattern = "MiniFilesExplorerOpen",
    callback = function()
      MiniFiles.set_bookmark("h", os.getenv("HOME") or vim.env.HOME, { desc = "Home" })
      MiniFiles.set_bookmark("c", vim.fn.stdpath("config"), { desc = "Config" })
      MiniFiles.set_bookmark("w", vim.fn.getcwd, { desc = "Working directory" })
      MiniFiles.set_bookmark("z", os.getenv("ZK_NOTEBOOK_DIR") or vim.env.HOME, { desc = "ZK" })
    end,
  })

  -- Set focused directory as current working directory
  local function remove_string(string1, string2)
    return string2:gsub(string1, "", 1)
  end
  local set_cwd = function()
    local path = (MiniFiles.get_fs_entry() or {}).path
    if path == nil then
      return vim.notify("Cursor is not on valid entry")
    end

    local pwd = vim.fs.dirname(path)
    vim.notify("PWD: " .. '.' .. vim.fn.pathshorten(pwd, 6))
    vim.fn.chdir(pwd)
  end

  -- Yank in register full path of entry under cursor
  local yank_path = function()
    local path = (MiniFiles.get_fs_entry() or {}).path
    if path == nil then
      return vim.notify("Cursor is not on valid entry")
    end
    vim.notify("Yanked: " .. path)
    vim.fn.setreg(vim.v.register, path)
  end

  -- Yank in register relative path of entry under cursor
  local yank_relpath = function()
    local path = (MiniFiles.get_fs_entry() or {}).path
    local cwd = vim.fn.getcwd() .. '/'
    local relpath = remove_string(cwd, path)
    if path == nil then
      return vim.notify("Cursor is not on valid entry")
    end
    vim.notify("Yanked: " .. relpath)
    vim.fn.setreg(vim.v.register, relpath)
  end

  local ui_open = function()
    vim.ui.open(MiniFiles.get_fs_entry().path)
  end
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
      local b = args.data.buf_id
      vim.keymap.set("n", "g~", set_cwd, { buffer = b, desc = "Set cwd" })
      vim.keymap.set("n", "gX", ui_open, { buffer = b, desc = "Open UI" })
      vim.keymap.set("n", "gY", yank_path, { buffer = b, desc = "Yank path" })
      vim.keymap.set("n", "gy", yank_relpath, { buffer = b, desc = "Yank relpath" })
    end,
  })
end)

later(function()
  require("mini.git").setup()
end)

later(function()
  require("mini.extra").setup()
end)

later(function()
  local hipatterns = require("mini.hipatterns")
  local hi_words = MiniExtra.gen_highlighter.words
  hipatterns.setup({
    highlighters = {
      fixme = hi_words({ "FIXME", "Fixme", "fixme" }, "MiniHipatternsFixme"),
      hack = hi_words({ "HACK", "Hack", "hack" }, "MiniHipatternsHack"),
      todo = hi_words({ "TODO", "Todo", "todo" }, "MiniHipatternsTodo"),
      note = hi_words({ "NOTE", "Note", "note" }, "MiniHipatternsNote"),

      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end)

later(function()
  require("mini.indentscope").setup()
end)

later(function()
  require("mini.jump").setup()
end)

later(function()
  local jump2d = require("mini.jump2d")
  jump2d.setup({
    spotter = jump2d.gen_spotter.pattern("[^%s%p]+"),
    allowed_lines = {
      blank = false,
      cursor_at = false
    },
    labels = "asdfghjklweruiopzxcnm,;",
    view = { dim = true, n_steps_ahead = 2 },
    mappings = {
      start_jumping = "sj",
    },
  })
  vim.keymap.set({ "n", "x", "o" }, "<leader><CR>", function()
    MiniJump2d.start(MiniJump2d.builtin_opts.single_character)
  end)
end)

later(function()
  local minikeymap = require("mini.keymap")
  minikeymap.setup()
  local map_multistep = minikeymap.map_multistep
  local tab_steps = {
    "blink_next",
    "pmenu_next",
    "increase_indent",
    "jump_after_close",
  }
  map_multistep("i", "<Tab>", tab_steps)
  local shifttab_steps = {
    "blink_prev",
    "pmenu_prev",
    "decrease_indent",
    "jump_before_open",
  }
  map_multistep("i", "<S-Tab>", shifttab_steps)
  map_multistep("i", "<CR>", {
    "blink_accept",
    "pmenu_accept",
    "minipairs_cr",
  })
  map_multistep("i", "<BS>", { "hungry_bs", "minipairs_bs" })

  local tab_steps_n = {
    "minisnippets_next",
    "jump_after_tsnode",
    "jump_after_close",
  }
  map_multistep("n", "<Tab>", tab_steps_n)

  local shifttab_steps_n = {
    "minisnippets_prev",
    "jump_before_tsnode",
    "jump_before_open",
  }
  map_multistep("n", "<S-Tab>", shifttab_steps_n)
end)

later(function()
  require("mini.move").setup({ options = { reindent_linewise = false } })
end)

later(function()
  require("mini.operators").setup({
    replace = {
      prefix = "gl"
    },
  })
end)

later(function()
  require("mini.pairs").setup({
    mappings = {
      ['"'] = { neigh_pattern = '[^%a\\"].' },
      ["'"] = { neigh_pattern = "[^%a\\'#]." },
    },
    modes = {
      insert = true,
      command = true,
      terminal = true
    }
  })
end)

later(function()
  require("mini.misc").setup({ make_global = { "put", "put_text", "stat_summary", "bench_time" } })
  --  MiniMisc.setup_auto_root()
  MiniMisc.setup_termbg_sync()
  MiniMisc.setup_restore_cursor()
end)

later(function()
  local choose_all = function()
    local mappings = MiniPick.get_picker_opts().mappings
    vim.api.nvim_input(mappings.mark_all .. mappings.choose_marked)
  end
  require("mini.pick").setup({
    mappings = {
      choose_marked = '<C-CR>',
      choose_all = { char = '<C-q>', func = choose_all },
    }
  })

  vim.ui.select = MiniPick.ui_select
  --  vim.api.nvim_set_hl(0, "MiniPickMatchCurrent", { bg = "#fe640b", bold = true })
end)

later(function()
  local snippets = require("mini.snippets")
  local gen_loader = snippets.gen_loader
  local lang_patterns = {
    markdown_inline = { "quarto.json" },
  }
  snippets.setup({
    snippets = {
      -- Load custom file with global snippets first (adjust for Windows)
      gen_loader.from_file(vim.fn.stdpath('config') .. "/snippets/global.json"),

      -- Load snippets based on current language by reading files from
      -- "snippets/" subdirectories from 'runtimepath' directories.
      gen_loader.from_lang({ lang_patterns = lang_patterns }),
    },
    --  expand = { match = match_strict },
  })
end)

later(function()
  require("mini.splitjoin").setup()
end)

later(function()
  require("mini.surround").setup()
  -- Disable `s` shortcut (use `cl` instead) for safer usage of 'mini.surround'
  vim.keymap.set({ "n", "x" }, "s", "<Nop>")
end)

later(function()
  require("mini.trailspace").setup()
end)

later(function()
  require("mini.visits").setup()
end)
