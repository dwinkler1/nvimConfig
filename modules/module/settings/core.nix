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

  # Binary name for the wrapper
  config.binName = lib.mkDefault "vv";

  # Prevent neovim from loading system-wide config
  config.settings.block_normal_config = true;

  # Don't symlink the config (we wrap it instead)
  config.settings.dont_link = lib.mkDefault false;

  # Create additional aliases for the binary
  config.settings.aliases = lib.mkDefault [ "vvim" ];

  # Enable wrapper handling of spec runtimeDeps (template pattern).
  config.settings.autowrapRuntimeDeps = true;

  # The wrapper library currently emits runtime PATH additions via `suffixVar`,
  # which lets host-level tools in `/usr/local/bin` win inside `nix run`.
  # Mirror those additions into `prefixVar` so wrapped Neovim resolves the
  # Nix-provided toolchain first while preserving existing wrapper behavior.
  config.prefixVar = lib.mkAfter config.suffixVar;
}
