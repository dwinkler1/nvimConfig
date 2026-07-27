--- Shared configuration / state table.
--- Plugin submodules attach their helpers to this table at runtime.
local M = {}

-- Detect whether this Neovim was launched via nixCats.
local nix = require('config.nix').init { non_nix_value = true }
M.isNixCats = nix.is_nix
M.nixConfig = nix

return M
