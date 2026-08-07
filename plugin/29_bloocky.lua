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
    keymaps = {
      toggle = '<leader>cb',
    },
  })
end)