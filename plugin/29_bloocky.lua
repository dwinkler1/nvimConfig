-- Bloocky: timeblocking calendar (day/week/month views), persisted to JSON.
-- Loaded via the `general` cat spec (nix mode) or MiniDeps (non-nix).
-- Default global toggle is <leader>tb, which collides with the terminal map
-- (toggle bracketed paste), so it is moved to the calendar/tasks group <leader>c.
local Config = require('config')

if not Config.isNixCats then
  local later = MiniDeps.later
  later(function()
    MiniDeps.add({ source = 'atiladefreitas/bloocky' })
  end)
end

local nix = require('config.nix')
local later = MiniDeps.later

later(function()
  if not nix.get_cat('general', false) then
    return
  end
  require('bloocky').setup({
    week_start = "monday",
    window = {
      -- Width per view: fraction of the editor width (or absolute columns if > 1).
      -- A single number applies to every view.
      width = {
        month = 0.99,
        week = 0.99,
        day = 0.8,
      },
      border = "rounded",
    },
    integrations = {
      dooing = {
        enabled = true,    -- show Dooing todos on their due date
        show_done = false, -- also show completed todos
      },
    },
    keymaps = {
      toggle = '<leader>cb',
    },
  })
end)
