-- Dooing: minimalist todo list manager with a floating window, persisted to JSON.
-- Loaded via the `general` cat spec (nix mode) or MiniDeps (non-nix).
-- Default globals <leader>td / <leader>tN occupy the terminal group, so the
-- todo toggles are moved to the calendar/tasks group <leader>c.
local Config = require('config')

if not Config.isNixCats then
  local later = MiniDeps.later
  later(function()
    MiniDeps.add({ source = 'atiladefreitas/dooing' })
  end)
end

local nix = require('config.nix')
local later = MiniDeps.later
local now = MiniDeps.now
later(function()
  if not nix.get_cat('general', false) then
    return
  end
  local dooing = require('dooing')
  require("dooing").setup({
    keymaps = {
      toggle_window = "<leader>cd",
      open_project_todo = "<leader>cD",
      show_due_notification = "<leader>cN",
      create_nested_task = "<leader>cn", -- Create nested subtask under current todo
      toggle_priority = "a",
    },
    calendar = {
      week_start_day = "monday",
    },
  })
  -- Remove Dooing's old defaults.
  vim.keymap.del("n", "<leader>td")
  vim.keymap.del("n", "<leader>tD")
  vim.keymap.del("n", "<leader>tN")

  -- Restore mappings overwritten by Dooing.
  local helpers = require('keymap.helpers')
  local nmap_leader = helpers.nmap_leader
  -- t is for 'terminal'
  nmap_leader("td", '<Cmd>lua Config.terminal.open_duckdb();Config.terminal.toggle_bracket()<CR>', 'Open DuckDB')
end)
