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
  vim.b[term_buf].slime_config = { jobid = job_id }
  
  return M.opt_term
end

-- Public functions
function M.open_in_terminal(cmd)
  local command = cmd or ""
  local current_window = vim.api.nvim_get_current_win()
  local code_buf = vim.api.nvim_get_current_buf()
  
  -- Open terminal and get buffer
  local term_buf = M.split_and_open_terminal()
  
  -- Send command if provided
  if command ~= "" then
    -- We can use standard slime sending if needed, or direct chan_send for initialization
    local job_id = vim.b[term_buf].terminal_job_id
    if job_id then
      vim.api.nvim_chan_send(job_id, command .. "\r")
    end
  end
  
  -- Configure slime for the ORIGINAL code buffer to point to this new terminal
  -- This makes "Send to Terminal" work immediately
  local slime_config = { jobid = vim.b[term_buf].terminal_job_id }
  
  -- Fix: Set the variable on the captured code buffer, not the current (terminal) buffer
  vim.api.nvim_buf_set_var(code_buf, "slime_config", slime_config)
  
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
