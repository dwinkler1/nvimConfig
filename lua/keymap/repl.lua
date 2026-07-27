--- Filetype-aware REPL/runner dispatcher.
--- Keeps the existing terminal setup intact; it only decides *which* runner
--- to use for the current buffer/filetype.

local M = {}

--- Resolve the filetype to use for dispatching.
--- Quarto buffers report `quarto`; R buffers report `r`. Fallback to the
--- actual filetype if no special handling is needed.
local function dispatch_ft()
  local ft = vim.bo.filetype
  if ft == "quarto" or ft == "rmd" or ft == "markdown" then
    return "quarto"
  end
  return ft
end

--- Send the current line to the active REPL/runner.
function M.send_line()
  local ft = dispatch_ft()

  if ft == "r" then
    -- R.nvim v1+ exposes a Lua API; try the modern `r.send` module first,
    -- then fall back to the older `r.run` module, and finally to <Plug>.
    local ok, rmod = pcall(require, "r.send")
    if not ok or not rmod then
      ok, rmod = pcall(require, "r.run")
    end
    if ok and rmod then
      if type(rmod.line) == "function" then
        rmod.line()
        return
      elseif type(rmod.send_line) == "function" then
        rmod.send_line()
        return
      end
    end
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Plug>RDSendLine", true, false, true),
      "m",
      false
    )
    return
  end

  if ft == "quarto" then
    local ok, runner = pcall(require, "quarto.runner")
    if ok and runner then
      if runner.run_line then
        runner.run_line()
      elseif runner.run_cell then
        runner.run_cell()
      end
      return
    end
  end

  -- Default: vim-slime (terminal).
  local line = vim.api.nvim_get_current_line()
  vim.fn["slime#send"](line .. "\n")
  -- Move to the next line, matching the previous behaviour.
  vim.cmd("normal! j")
end

--- Send the current visual selection to the active REPL/runner.
function M.send_selection()
  local ft = dispatch_ft()

  if ft == "r" then
    -- Prefer R.nvim v1+ Lua API; try the modern `r.send` module first,
    -- then fall back to the older `r.run` module, and finally to <Plug>.
    local ok, rmod = pcall(require, "r.send")
    if not ok or not rmod then
      ok, rmod = pcall(require, "r.run")
    end
    if ok and rmod then
      if type(rmod.selection) == "function" then
        rmod.selection()
        return
      elseif type(rmod.send_selection) == "function" then
        rmod.send_selection()
        return
      end
    end
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Plug>RSendSelection", true, false, true),
      "m",
      false
    )
    return
  end

  -- For Quarto/others, fall back to vim-slime's visual send.
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<Plug>SlimeRegionSend", true, false, true),
    "m",
    false
  )
end

return M
