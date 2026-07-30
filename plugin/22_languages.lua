local Config = require('config')

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

-- Linting (via nvim-lint)
later(function()
  Config.add("nvim-lint")
  local lint_ok, lint = pcall(require, "lint")
  if not lint_ok then
    return
  end

  -- R code style via lintr (must be available in the R runtime).
  -- lintr::lint() returns a "lints" object; format() turns it into the
  -- standard "file:line:col: severity: message" lines.
  lint.linters.lintr = {
    cmd = "Rscript",
    stdin = false,
    args = {
      "-e",
      "args <- commandArgs(trailingOnly=TRUE); l <- lintr::lint(args[1]); if (length(l) > 0) cat(paste(format(l), collapse='\\n'), '\\n')",
    },
    append_fname = true,
    stream = "both",
    ignore_exitcode = true,
    parser = function(output, bufnr, linter_cwd)
      local diagnostics = {}
      -- Expected format: /path/file.R:10:5: style: Some message
      local severity_map = {
        style = vim.diagnostic.severity.INFO,
        warning = vim.diagnostic.severity.WARN,
        error = vim.diagnostic.severity.ERROR,
      }
      for line in output:gmatch("[^\r\n]+") do
        -- Capture the file path as well so lnum/col line up with the numbers.
        local path, lnum, col, severity, message = line:match("^(.-):(%d+):(%d+):%s*(%w+):%s*(.+)$")
        if path and lnum and col and severity then
          local line_num = tonumber(lnum)
          local col_num = tonumber(col)
          table.insert(diagnostics, {
            bufnr = bufnr,
            lnum = math.max(0, line_num - 1),
            col = math.max(0, col_num - 1),
            end_lnum = line_num - 1,
            end_col = col_num,
            severity = severity_map[severity:lower()] or vim.diagnostic.severity.WARN,
            message = message or "lintr issue",
            source = "lintr",
          })
        end
      end
      return diagnostics
    end,
  }

  lint.linters_by_ft = {
    r = { "lintr" },
    rmd = { "lintr" },
    quarto = { "lintr" },
  }

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("LintOnEvents", { clear = true }),
    callback = function()
      lint.try_lint()
    end,
  })
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
