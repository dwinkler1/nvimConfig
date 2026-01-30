{
  config,
  lib,
  ...
}:
{
  # Point to the directory containing init.lua, plugin/, lua/, etc.
  config.settings.config_directory = ../../..;

  # Default colorscheme and background
  config.settings.colorscheme = lib.mkDefault "kanagawa";
  config.settings.background = lib.mkDefault "dark";

  # Enable RC wrapping (allows neovim to find the config)
  config.settings.wrapRc = lib.mkDefault true;

  # Lua packages available to neovim (for :lua require())
  config.settings.nvim_lua_env = lp:
    lib.optionals (config.cats.general or false) [ lp.tiktoken_core ];

  # Binary name for the wrapper
  config.binName = lib.mkDefault "n";

  # Prevent neovim from loading system-wide config
  config.settings.block_normal_config = true;

  # Don't symlink the config (we wrap it instead)
  config.settings.dont_link = false;

  # Create additional aliases for the binary
  config.settings.aliases = [ "vvim" ];

  # Enable wrapper handling of spec runtimeDeps (template pattern).
  config.settings.autowrapRuntimeDeps = true;
}
