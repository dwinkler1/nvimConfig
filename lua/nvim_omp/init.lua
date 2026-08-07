-- omp bridge: expose an RPC socket so the omp harness can read this Neovim
-- instance's buffers on demand. Read-only on the agent side; this module only
-- owns the socket lifecycle.
--
-- Contract
--   * Socket path: $NVIM_OMP_SOCKET if set, else <stdpath('state')>/omp.sock
--     (~/.local/state/nvim/omp.sock on macOS, ~/.local/state/nvim/omp.sock
--     elsewhere). The omp-side tool in .omp/tools/nvim_buffers.mjs resolves the
--     *same* path, so the two sides agree without configuration.
--   * The agent reads buffers by evaluating read-only nvim API expressions over
--     the socket with `nvim --server <path> --remote-expr 'json_encode(...)'`.
--     Nothing here writes buffers or executes model-supplied commands.
local M = {}

local SOCKET_NAME = "omp.sock"

-- Resolve the deterministic socket path. Copies the rule on the omp side; keep
-- the two files in sync when changing the fallback or env override.
function M.socket_path()
  local env = vim.env.NVIM_OMP_SOCKET
  if env and env ~= "" then
    return env
  end
  return vim.fn.stdpath("state") .. "/" .. SOCKET_NAME
end

-- Start the RPC listener. Returns the live socket path, or nil.
-- A second instance cannot bind the same address. This function deliberately
-- never removes an existing socket file: a failed liveness probe must not
-- disconnect another live Neovim instance.
-- If a crash leaves a stale socket, remove it manually only after confirming
-- that no Neovim process owns the path, then restart vv.
function M.start()
  if vim.v.headless == 1 then
    -- Headless runs (tests, CI) get no socket; nothing should depend on one.
    return nil
  end

  local path = M.socket_path()
  local ok, res = pcall(vim.fn.serverstart, path)
  if ok and type(res) == "string" and res ~= "" then
    -- serverstart returns the bound address string (e.g. "/tmp/omp.sock").
    vim.notify("nvim_omp: RPC socket ready at " .. path, vim.log.levels.INFO)
    return path
  end

  vim.notify(
    "nvim_omp: could not bind RPC socket at " .. path
    .. "; another instance may own it or a stale socket needs manual cleanup.",
    vim.log.levels.WARN
  )
  return nil
end

return M
