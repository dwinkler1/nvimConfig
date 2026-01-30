inputs:
{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
{
  # ============================================================================
  # IMPORTS
  # ============================================================================
  # Import the base neovim wrapper module and all configuration modules

  imports = [
    wlib.wrapperModules.neovim
    ./module/specs/deps.nix
    ./module/specs/plugins.nix
    ./module/specs/cats-enable.nix
    ./module/settings/core.nix
    ./module/settings/cats.nix
    ./module/settings/env.nix
    ./module/settings/hosts.nix
    ./module/settings/lang-packages.nix
    ./module/settings/runtime-path.nix
  ];

  # ============================================================================
  # HELPER FUNCTIONS
  # ============================================================================
  # Utilities for working with plugin inputs

  options.nvim-lib.neovimPlugins = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf wlib.types.stringable;
    default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
  };

  options.nvim-lib.pluginsFromPrefix = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      prefix: inputs:
      lib.pipe inputs [
        builtins.attrNames
        (builtins.filter (s: lib.hasPrefix prefix s))
        (map (
          input:
          let
            name = lib.removePrefix prefix input;
          in
          {
            inherit name;
            value = config.nvim-lib.mkPlugin name inputs.${input};
          }
        ))
        builtins.listToAttrs
      ];
  };

  # ============================================================================
  # CONFIGURATION
  # ============================================================================
  # Pass cats configuration to neovim and expose metadata

  config.settings.cats = config.cats;
  config.info.cats = config.cats;
  config.info.nixCats_config_location = config.settings.config_directory;
  config.info.nixCats_wrapRc = config.settings.wrapRc or false;
  config.info.nixCats_configDirName = "nvim";
}
