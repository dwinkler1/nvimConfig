local Config = require('config')

-- Domain-specific keymap modules. Core must load first because it defines the
-- leader clue groups used by the mini.clue setup in the startup plugins.
require('keymap.core')
require('keymap.leader')
require('keymap.terminal')

-- Re-export the shared config table for backwards compatibility with any
-- external code or keymap strings that still reference the global `Config`.
_G.Config = Config
