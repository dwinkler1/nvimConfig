local Config = require('config')

-- Domain-specific keymap modules. Core must load first because it defines the
-- leader clue groups used by the mini.clue setup in the startup plugins.
require('keymap.core')
require('keymap.leader')
require('keymap.terminal')

-- `_G.Config` is set by `init.lua:2` once at start-up; no need to re-export
-- here. The single source of truth is `init.lua` so future refactors don't
-- have to chase which file currently publishes the alias.
