local function assert_ok(value, message)
  if not value then
    error(message or "assertion failed")
  end
end

local ok, nix = pcall(require, "config.nix")
assert_ok(ok, "Failed to require config.nix")

local init_ok, helper = pcall(function()
  return nix.init({ non_nix_value = true })
end)
assert_ok(init_ok and helper, "Failed to initialize config.nix helper")

-- Basic shape checks
assert_ok(type(helper.is_nix) == "boolean", "Expected helper.is_nix to be boolean")

-- Cat/setting access should return defaults without errors
local cat_value = helper.get_cat("general", true)
assert_ok(type(cat_value) == "boolean", "Expected get_cat to return boolean")

local background = helper.get_setting("dark", "background")
assert_ok(type(background) == "string", "Expected get_setting to return string")

local info_value = helper.get_info("nvim", "nixCats_configDirName")
assert_ok(type(info_value) == "string", "Expected get_info to return string")

print("[tests/init.lua] nix helper smoke test passed")
