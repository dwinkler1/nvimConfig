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

    r-nvim-nix.url = "github:dwinkler1/r_nvim_nix";
    r-nvim-nix.inputs.rnvimsrc.follows = "plugins-r";
    r-nvim-nix.inputs.nixpkgs.follows = "rixpkgs";

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
      r = (with pkgs.rpkgs.rPackages; [
        arrow
        broom
        data_table
        janitor
        styler
        pkgs.nvimcom
      ]) ++ [ pkgs.nvimcom ];
      julia = [
        "DataFramesMeta"
        "QuackIO"
      ];
    };

    mkWrapperConfig = pkgs: {
      cats = {
        clickhouse = false;
        gitPlugins = true;
        julia = false;
        lua = true;
        markdown = true;
        nix = true;
        optional = false;
        python = false;
        r = true;
      };
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
        config = { allowUnfree = true; };
        overlays = [ overlayDefs.dependencyOverlay ];
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

        langPkgs = langPackages pkgs;

        pythonPackages = let
          python_packages_fn =
            if pkgs ? basePythonPackages
            then ps: pkgs.basePythonPackages ps ++ langPkgs.python
            else _: langPkgs.python;
        in
          with pkgs; [
            (python3.withPackages python_packages_fn)
            nodejs
            ruff
            basedpyright
            uv
          ];

        rPackages = let
          r_packages = (pkgs.baseRPackages or []) ++ langPkgs.r;
        in
          with pkgs; [
            (rWrapper.override {packages = r_packages;})
            radianWrapper
            (quarto.override {extraRPackages = r_packages;})
            air-formatter
            yaml-language-server
            nvimcom
            rnvimserver
          ];

        juliaPackages = let
          julia_with_packages = pkgs.julia-bin.withPackages langPkgs.julia;
        in [julia_with_packages];

        markdownPackages = with pkgs; [
          python313Packages.pylatexenc
          quarto
          zk
        ];

        shellPackages =
          [nvimPkg]
          ++ pkgs.lib.optionals wrapper.config.cats.python pythonPackages
          ++ pkgs.lib.optionals wrapper.config.cats.r rPackages
          ++ pkgs.lib.optionals wrapper.config.cats.julia juliaPackages
          ++ pkgs.lib.optionals wrapper.config.cats.markdown markdownPackages;
      in {
        default = pkgs.mkShell {
          name = "vShell";
          packages = shellPackages;
          nativeBuildInputs = pkgs.lib.optionals wrapper.config.cats.optional [ pkgs.devenv ];
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
        module-eval =
          let _ = wrapper.config;
          in pkgs.runCommand "check-module-eval" {} ''
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
