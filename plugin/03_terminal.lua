local Config = require('config')

-- vim-slime target: use Neovim's built-in terminal.
-- Must be set before any slime send happens.
vim.g.slime_target = "neovim"

local M = {}

-- Configuration
Config.opt_bracket = true
M.opt_term = nil

-- Default terminal commands
-- Users can override this via Config.terminal_commands in their setup
local defaults = {
  clickhouse_client = "clickhouse client -m",
  clickhouse_local = "clickhouse local -m",
  duckdb = "duckdb",
  julia = "julia",
  python = "ipython",
  shell = "echo 'Hello " .. vim.env.USER .. "!'",
}

-- Registry of terminal commands
M.commands = vim.tbl_deep_extend("force", defaults, Config.terminal_commands or {})

-- Bracket paste control
function M.toggle_bracket()
  Config.opt_bracket = not Config.opt_bracket
  vim.g.slime_bracketed_paste = Config.opt_bracket
  return Config.opt_bracket
end

-- Terminal management
function M.split_and_open_terminal()
  vim.cmd("below terminal")
  vim.cmd("resize " .. math.floor(vim.fn.winheight(0) * 0.9))
  local term_buf = vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())
  M.opt_term = term_buf

  -- Set buffer-local variables for vim-slime
  local job_id = vim.b[term_buf].terminal_job_id
  if not job_id then
    vim.notify("Terminal job id not available", vim.log.levels.WARN)
    return term_buf
  end
  vim.b[term_buf].slime_config = { jobid = job_id }

  return M.opt_term
end

-- Public functions
function M.open_in_terminal(cmd)
  local command = cmd or ""
  local current_window = vim.api.nvim_get_current_win()
  local code_buf = vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(code_buf) then
    vim.notify("Code buffer is not valid", vim.log.levels.ERROR)
    return
  end

  -- Open terminal and get buffer
  local term_buf = M.split_and_open_terminal()

  if not term_buf or not vim.api.nvim_buf_is_valid(term_buf) then
    vim.notify("Failed to open terminal buffer", vim.log.levels.ERROR)
    return
  end

  -- Send command if provided
  local job_id = vim.b[term_buf].terminal_job_id
  if command ~= "" then
    if not job_id then
      vim.notify("Terminal job not ready, cannot send command", vim.log.levels.WARN)
    else
      local ok, err = pcall(vim.api.nvim_chan_send, job_id, command .. "\r")
      if not ok then
        vim.notify("Failed to send command to terminal: " .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end

  -- Configure slime for the ORIGINAL code buffer to point to this new terminal
  -- This makes "Send to Terminal" work immediately
  if job_id then
    local slime_config = { jobid = job_id }

    -- Fix: Set the variable on the captured code buffer, not the current (terminal) buffer
    local ok, err = pcall(vim.api.nvim_buf_set_var, code_buf, "slime_config", slime_config)
    if not ok then
      vim.notify("Failed to set slime_config on code buffer: " .. tostring(err), vim.log.levels.ERROR)
    end
  end

  -- Switch back to code buffer
  vim.api.nvim_set_current_win(current_window)
end

-- Predefined terminal commands
for name, command in pairs(M.commands) do
  M["open_" .. name] = function()
    M.open_in_terminal(command)
  end
end

Config.terminal = M
