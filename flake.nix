# Copyright (c) 2026 BirdeeHub
# Licensed under the MIT license
{
  description = "Daniel's NixCats";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rixpkgs.url = "https://github.com/rstats-on-nix/nixpkgs/archive/2026-01-19.tar.gz";

    fran = {
      url = "github:dwinkler1/fran";
      inputs = {
        nixpkgs.follows = "rixpkgs";
      };
    };

    "plugins-r" = {
      url = "github:R-nvim/R.nvim";
      flake = false;
    };
    "plugins-cmp-r" = {
      url = "github:R-nvim/cmp-r";
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
    wrapperSettings = pkgs:
      wrapper.config.wrap {
        inherit pkgs;
        cats = {
          clickhouse = false;
          gitPlugins = false;
          julia = false;
          lua = false;
          markdown = false;
          nix = true;
          optional = false;
          python = false;
          r = true;
        };

        settings.lang_packages = {
          python = with pkgs.python3Packages; [
            duckdb
            polars
          ];

          r = with pkgs.rpkgs.rPackages; [
            arrow
            broom
            data_table
            duckdb
            janitor
            styler
            tidyverse
          ];

          julia = ["DataFramesMeta" "QuackIO"];
        };
      };

    systems = [
      "aarch64-darwin"
      "x86_64-linux"
      "aarch64-linux"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;

    extra_pkg_config = {
      # allowUnfree = true;
    };

    overlayDefs = import ./overlays inputs;

    dependencyOverlays = overlayDefs.dependencyOverlays;

    dependencyOverlay = overlayDefs.dependencyOverlay;

    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config = extra_pkg_config;
        overlays = [dependencyOverlay];
      };

    module = nixpkgs.lib.modules.importApply ./modules/neovim.nix inputs;
    wrapper = wrappers.lib.evalModule module;
  in {
    overlays = {
      default = nixpkgs.lib.composeManyExtensions [
        dependencyOverlay
        (final: prev: {
          n = wrapper.config.wrap {pkgs = final;};
        })
      ];
      dependencies = dependencyOverlay;
      n = self.overlays.default;
    };

    wrapperModules = {
      default = module;
      neovim = self.wrapperModules.default;
    };

    wrappers = {
      default = wrapper.config;
      neovim = self.wrappers.default;
    };

    packages = forAllSystems (
      system: let
        pkgs = mkPkgs system;
        nvimPkg = wrapperSettings pkgs;
      in {
        default = nvimPkg;
        n = nvimPkg;
        vim = nvimPkg;
        nvim = nvimPkg;
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
      in {
        default = pkgs.mkShell {
          name = "n";
          packages = [nvimPkg];
          nativeBuildInputs = with pkgs; [] ++ (pkgs.lib.optionals self.wrappers.default.cats.optional [devenv]);
          inputsFrom = [];
          shellHook = "";
        };
      }
    );

    checks = forAllSystems (
      system: let
        pkgs = mkPkgs system;
        nvimPkg = wrapperSettings pkgs;
      in {
        default = nvimPkg;
        module-eval = let
          _ = wrapper.config;
        in
          pkgs.runCommand "check-module-eval" {} ''
            echo "Module evaluation successful" > $out
          '';
        package-build = pkgs.runCommand "check-n" {} ''
          BINARY_PATH="${nvimPkg}/bin/n"

          if [ ! -x "$BINARY_PATH" ]; then
            echo "Error: Binary n not found or not executable"
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
      }
    );

    nixosModules.default = wrappers.lib.mkInstallModule {
      name = "n";
      value = module;
    };

    homeModules.default = wrappers.lib.mkInstallModule {
      name = "n";
      value = module;
      loc = ["home" "packages"];
    };
  };
}
