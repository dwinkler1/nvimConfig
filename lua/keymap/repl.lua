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
    -- R.nvim v1+ exposes a Lua API; fall back to the legacy <Plug> mappings
    -- if a v0.x build is still in use.
    local ok, rrun = pcall(require, "r.run")
    if ok and rrun and type(rrun.send_line) == "function" then
      rrun.send_line()
      return
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
  vim.cmd("SlimeSendCurrentLine")
  -- Move to the next line, matching the previous behaviour.
  vim.cmd("normal! j")
end

--- Send the current visual selection to the active REPL/runner.
function M.send_selection()
  local ft = dispatch_ft()

  if ft == "r" then
    -- Prefer R.nvim v1+ Lua API; fall back to <Plug> if unavailable.
    local ok, rrun = pcall(require, "r.run")
    if ok and rrun and type(rrun.send_selection) == "function" then
      rrun.send_selection()
      return
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
