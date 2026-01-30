local M = {}

local function detect_nix()
  if vim.g.nix_info_plugin_name ~= nil then
    return true
  end
  if vim.g[ [[nixCats-special-rtp-entry-nixCats]] ] ~= nil then
    return true
  end
  return false
end

M.is_nix = detect_nix()
M.non_nix_default = true

local function setup_nixcats(non_nix_value)
  if M.is_nix then
    return
  end

  local ok, utils = pcall(require, "nixCatsUtils")
  if ok and utils and utils.setup then
    utils.setup { non_nix_value = non_nix_value }
  end
end

local function init_from_nix_info()
  if vim.g.nix_info_plugin_name == nil then
    return nil
  end

  local ok, nix_info = pcall(require, vim.g.nix_info_plugin_name)
  if not ok or not nix_info then
    return nil
  end

  local function cat_lookup(cat)
    if type(cat) == "table" then
      for _, name in ipairs(cat) do
        if nix_info(false, "settings", "cats", name) or nix_info(false, "info", "cats", name) then
          return true
        end
      end
      return false
    end
    return nix_info(false, "settings", "cats", cat) or nix_info(false, "info", "cats", cat)
  end

  local nc = setmetatable({
    cats = nix_info.settings and nix_info.settings.cats or {},
    settings = nix_info.settings or {},
    get = function(_, default, ...) return nix_info(default, ...) end,
  }, {
    __call = function(_, default, ...)
      if select("#", ...) == 0 then
        return cat_lookup(default)
      end
      return nix_info(default, ...)
    end,
    __index = nix_info,
  })

  _G.nixCats = nc
  package.preload['nixCats.cats'] = function()
    return setmetatable(_G.nixCats.cats or {}, getmetatable(_G.nixCats))
  end

  return nc
end

local function get_nixcats()
  if _G.nixCats then
    return _G.nixCats
  end

  local nc = init_from_nix_info()
  if nc then
    return nc
  end

  local ok, nc_module = pcall(require, "nixCats")
  if ok and nc_module then
    return nc_module
  end

  return nil
end

function M.init(opts)
  local non_nix_value = true
  if type(opts) == "table" and type(opts.non_nix_value) == "boolean" then
    non_nix_value = opts.non_nix_value
  end

  M.non_nix_default = non_nix_value
  setup_nixcats(non_nix_value)
  get_nixcats()
  M.is_nix = detect_nix()
  return M
end

local function cat_enabled(nc, cat, default)
  if not nc then
    return default
  end

  if type(cat) == "table" then
    for _, name in ipairs(cat) do
      if nc(name) then
        return true
      end
    end
    return default
  end

  local val = nc(cat)
  if val == nil then
    return default
  end
  return val
end

function M.get_cat(cat, default)
  if default == nil then
    default = M.non_nix_default
  end
  if not M.is_nix then
    return default
  end
  local nc = get_nixcats()
  return cat_enabled(nc, cat, default)
end

function M.get_setting(default, ...)
  if not M.is_nix then
    return default
  end
  local nc = get_nixcats()
  if not nc then
    return default
  end

  local value = nc(default, "settings", ...)
  if value == nil then
    return default
  end
  return value
end

function M.get_info(default, ...)
  if not M.is_nix then
    return default
  end
  local nc = get_nixcats()
  if not nc then
    return default
  end

  local value = nc(default, "info", ...)
  if value == nil then
    return default
  end
  return value
end

return M
