{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.settings = {
    # Built-in language libraries composed into every language spec.
    # Consumers extend via settings.lang_packages, which is APPENDED to these.
    langPackageDefaults = lib.mkOption {
      type = lib.types.submodule {
        options = {
          python = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
          };
          r = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
          };
          julia = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      };
      default = { };
    };

    lang_packages = lib.mkOption {
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
        Project-specific language libraries. Appended to settings.langPackageDefaults
        in each language spec's runtime packages.
      '';
    };
  };

  config.settings.langPackageDefaults = {
    python = with pkgs.python3Packages; [
      duckdb
      polars
    ];
    r = with pkgs.rpkgs.rPackages; [
      arrow
      broom
      data_table
      janitor
      styler
      # vscDebugger is not on CRAN/Bioconductor, so it is not available in
      # pkgs.rpkgs.rPackages. Install it manually in your R library if you
      # want to use the nvim-dap R adapter (see plugin/26_dap.lua).
      # vscDebugger
      lintr
    ];
    julia = [
      "DataFramesMeta"
      "QuackIO"
    ];
  };
}
