{
  config,
  lib,
  ...
}:
{
  options.settings.lang_packages = lib.mkOption {
    type = lib.types.submodule {
      options = {
        python = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Additional Python-related packages appended to the python spec (overlay defaults remain).";
        };
        r = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Additional R-related packages appended to the r spec (overlay defaults remain).";
        };
        julia = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional Julia packages (names) passed to julia-bin.withPackages.";
        };
      };
    };
    default = { };
    description = ''
      Language-specific package overrides appended to each language spec's extraPackages.
      Intended for flake.nix overrides via wrapper.config.wrap.
    '';
  };

  config.settings.lang_packages = {
    python = lib.mkDefault [ ];
    r = lib.mkDefault [ ];
    julia = lib.mkDefault [ ];
  };
}
