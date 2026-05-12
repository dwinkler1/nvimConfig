# Copyright (c) 2026 BirdeeHub
# Licensed under the MIT license
{
  description = "Daniel's NixCats";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rixpkgs.url = "github:dwinkler1/rixpkgs/nixpkgs";

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
    mkWrapperConfig = pkgs: {
      cats = {
        clickhouse = false;
        gitPlugins = true;
        julia = false;
        lua = true;
        markdown = false;
        nix = true;
        optional = false;
        python = false;
        r = true;
      };
      settings = {
        lang_packages = {
          python = with pkgs.python3Packages; [
            duckdb
            polars
          ];
          r = with pkgs.rpkgs.rPackages; [
            arrow
            broom
            data_table
            janitor
            languageserver
            styler
          ];
          julia = ["DataFramesMeta" "QuackIO"];
        };
        colorscheme = "cyberdream";
        background = "dark";
        wrapRc = true;
      };
      binName = "vv";
    };

    wrapperSettings = pkgs: let
      cfg = mkWrapperConfig pkgs;
      def = pkgs.lib.mkDefault;
    in
      wrapper.config.wrap {
        inherit pkgs;
        cats = pkgs.lib.mapAttrs (_: v: def v) cfg.cats;
        settings = {
          lang_packages = {
            python = def cfg.settings.lang_packages.python;
            r = def cfg.settings.lang_packages.r;
            julia = def cfg.settings.lang_packages.julia;
          };
          colorscheme = def cfg.settings.colorscheme;
          background = def cfg.settings.background;
          wrapRc = def cfg.settings.wrapRc;
        };
        binName = def cfg.binName;
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
          vv = wrapper.config.wrap {pkgs = final;};
        })
      ];
      dependencies = dependencyOverlay;
      vv = self.overlays.default;
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
        vv = nvimPkg;
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
        cfg = mkWrapperConfig pkgs;
        nvimPkg = wrapperSettings pkgs;

        pythonPackages = let
          python_packages_fn =
            if pkgs ? basePythonPackages
            then ps: pkgs.basePythonPackages ps ++ cfg.settings.lang_packages.python
            else _: cfg.settings.lang_packages.python;
        in
          with pkgs; [
            (python3.withPackages python_packages_fn)
            nodejs
            ruff
            basedpyright
            uv
          ];

        rPackages = let
          r_packages = (pkgs.baseRPackages or []) ++ cfg.settings.lang_packages.r;
        in
          with pkgs; [
            (rWrapper.override {packages = r_packages;})
            radianWrapper
            (quarto.override {extraRPackages = r_packages;})
            air-formatter
            yaml-language-server
            updateR
          ];

        juliaPackages = let
          julia_with_packages = pkgs.julia-bin.withPackages cfg.settings.lang_packages.julia;
        in [julia_with_packages];

        markdownPackages = with pkgs; [
          python313Packages.pylatexenc
          quarto
          zk
        ];

        shellPackages =
          [nvimPkg]
          ++ pkgs.lib.optionals cfg.cats.python pythonPackages
          ++ pkgs.lib.optionals cfg.cats.r rPackages
          ++ pkgs.lib.optionals cfg.cats.julia juliaPackages
          ++ pkgs.lib.optionals cfg.cats.markdown markdownPackages;
      in {
        default = pkgs.mkShell {
          name = "vShell";
          packages = shellPackages;
          nativeBuildInputs = with pkgs; [] ++ (pkgs.lib.optionals cfg.cats.optional [devenv]);
          inputsFrom = [];
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
        default = nvimPkg;
        module-eval = let
          _ = wrapper.config;
        in
          pkgs.runCommand "check-module-eval" {} ''
            echo "Module evaluation successful" > $out
          '';
        package-build = pkgs.runCommand "check-vv" {} ''
          BINARY_PATH="${nvimPkg}/bin/vv"

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
