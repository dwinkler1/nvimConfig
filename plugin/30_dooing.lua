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

later(function()
  if not nix.get_cat('general', false) then
    return
  end
  require('dooing').setup({
    keymaps = {
      toggle_window = '<leader>cd',
      open_project_todo = '<leader>cD',
      show_due_notification = '<leader>cN',
    },
  })
end)