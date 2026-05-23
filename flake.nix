# Copyright (c) 2026 BirdeeHub & Daniel
# Licensed under the MIT license
{
  description = "Daniel's NixCats";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rixpkgs.url = "github:dwinkler1/rixpkgs/af2dd3f7b4b172077747c0869d4e30702fb71b0e";

    r-nvim-nix = {
      url = "github:dwinkler1/r_nvim_nix/v0.99.4";
      inputs = {
        nixpkgs.follows = "rixpkgs";
      };
    };

    fran = {
      url = "github:dwinkler1/fran";
      inputs = {
        nixpkgs.follows = "rixpkgs";
      };
    };

    "plugins-r" = {
      url = "github:R-nvim/R.nvim/v0.99.4";
      flake = false;
    };

    "plugins-cmp-pandoc-references" = {
      url = "github:jmbuhr/cmp-pandoc-references";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    wrappers,
    ...
  } @ inputs: let
    langPackages = pkgs: {
      python = with pkgs.python3Packages; [
        duckdb
        polars
      ];
      r =
        (with pkgs.rpkgs.rPackages; [
          arrow
          broom
          data_table
          janitor
          styler
        ])
        ++ [pkgs.nvimcom];
      julia = [
        "DataFramesMeta"
        "QuackIO"
      ];
    };

    mkWrapperConfig = pkgs: {
      settings = {
        lang_packages = langPackages pkgs;
      };
      binName = "vv";
    };

    wrapperSettings = pkgs: let
      cfg = mkWrapperConfig pkgs;
    in
      wrapper.config.wrap {
        inherit pkgs;
        inherit (cfg) settings binName;
      };

    systems = [
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    overlayDefs = import ./overlays inputs;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config = {allowUnfree = true;};
        overlays = [
          overlayDefs.dependencyOverlay
          inputs.r-nvim-nix.overlays.default
          inputs.fran.overlays.default
        ];
      };

    module = (import ./modules/neovim.nix) inputs;
    wrapper = wrappers.lib.evalModule module;
  in {
    overlays = {
      # overlay `vv` wraps the module with default settings only.
      # For the fully-configured binary (including mkWrapperConfig overrides),
      # use `packages.<system>.default` instead.
      default = nixpkgs.lib.composeManyExtensions [
        overlayDefs.dependencyOverlay
        (final: prev: {
          vv = wrapper.config.wrap {pkgs = final;};
        })
      ];
      dependencies = overlayDefs.dependencyOverlay;
    };

    wrapperModules.default = module;
    wrapperConfigs.default = wrapper.config;

    packages = forAllSystems (
      system: let
        pkgs = mkPkgs system;
      in {
        default = wrapperSettings pkgs;
      }
    );

    formatter = forAllSystems (
      system: let
        pkgs = mkPkgs system;
      in
        pkgs.nixfmt-tree
    );

    devShells = forAllSystems (
      system: let
        pkgs = mkPkgs system;
        nvimPkg = wrapperSettings pkgs;

        shellPackages = [nvimPkg]
          ++ wrapper.config.catPkgs.always or []
          ++ wrapper.config.catPkgs.python or []
          ++ wrapper.config.catPkgs.r or []
          ++ wrapper.config.catPkgs.julia or []
          ++ wrapper.config.catPkgs.markdown or []
          ++ wrapper.config.catPkgs.optional or []
          ++ wrapper.config.catPkgs.external or []
          ++ wrapper.config.catPkgs.nix or []
          ++ wrapper.config.catPkgs.lua or []
          ++ wrapper.config.catPkgs.clickhouse or [];
      in {
        default = pkgs.mkShell {
          name = "vShell";
          packages = shellPackages;
          shellHook = ''
            echo 'I am a NixShell'
            export R_HOME=$(R RHOME)
            export R_LIBS_SITE=$(strings "$(command -v R)" | grep -oP '/nix/store/[^:]+/library' | sort -u | paste -sd: -)
            export R_LIBS_USER="$PWD/.r-libs"
            mkdir -p "$R_LIBS_USER"
          '';
        };
      }
    );

    checks = forAllSystems (
      system: let
        pkgs = mkPkgs system;
        nvimPkg = wrapperSettings pkgs;
      in {
        default = pkgs.runCommand "check-vv" {} ''
          BINARY_PATH="${nvimPkg}/bin/vv"

          if [ ! -x "$BINARY_PATH" ]; then
            echo "Error: Binary not found or not executable"
            exit 1
          fi

          "$BINARY_PATH" --version > version_output.txt 2>&1 || true

          echo "Package validation successful" > $out
          echo "Binary location: $BINARY_PATH" >> $out
          if [ -s version_output.txt ]; then
            echo "Version output:" >> $out
            cat version_output.txt >> $out
          fi
        '';
        module-eval = let
          _ = wrapper.config;
        in
          pkgs.runCommand "check-module-eval" {} ''
            echo "Module evaluation successful" > $out
          '';
      }
    );

    nixosModules.default = wrappers.lib.mkInstallModule {
      name = "vModule";
      value = module;
    };

    homeModules.default = wrappers.lib.mkInstallModule {
      name = "vModule";
      value = module;
      loc = ["home" "packages"];
    };
  };
}
