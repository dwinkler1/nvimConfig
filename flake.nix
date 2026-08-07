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
    rixpkgs.url = "github:dwinkler1/rixpkgs/nixpkgs";

    r-nvim-nix = {
      url = "github:dwinkler1/r_nvim_nix/v1.0.0";
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

    "plugins-cmp-pandoc-references" = {
      url = "github:jmbuhr/cmp-pandoc-references";
      flake = false;
    };

    "plugins-bloocky" = {
      url = "github:atiladefreitas/bloocky";
      flake = false;
    };

    "plugins-dooing" = {
      url = "github:atiladefreitas/dooing";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    wrappers,
    ...
  } @ inputs: let
    devShellCatOrder = [
      "always"
      "clickhouse"
      "external"
      "julia"
      "lua"
      "markdown"
      "nix"
      "optional"
      "python"
      "r"
      "treesitterParsers"
    ];
    evalWithPkgs = pkgs: extraModules:
      wrappers.lib.evalModules {
        specialArgs = {
          inherit pkgs;
        };
        modules =
          [
            module
          ]
          ++ extraModules;
      };
    mkDevShellPackages = config:
      builtins.concatLists (map (name: config.catPkgs.${name} or []) devShellCatOrder);
    mkShellHook = config:
      ''
        echo 'I am a NixShell'
      ''
      + nixpkgs.lib.optionalString (config.cats.r or false) ''
        export R_HOME=$(R RHOME)
        export R_LIBS_SITE=$(strings "$(command -v R)" | rg -o '/nix/store/[^:]+/library' | sort -u | paste -sd: -)
        export R_LIBS_USER="$PWD/.r-libs"
        mkdir -p "$R_LIBS_USER"
      '';

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
        ];
      };

    module = (import ./modules/neovim.nix) inputs;
  in {
    lib = {
      eval = {pkgs, modules ? []}: evalWithPkgs pkgs modules;
      mkWrapper = {pkgs, modules ? []}: (evalWithPkgs pkgs modules).config.wrap {inherit pkgs;};
      devShellPackages = config: mkDevShellPackages config;
      shellHook = config: mkShellHook config;
    };

    overlays = {
      # overlay `vv` wraps the module with default settings only.
      # It is evaluated against the final package set so module defaults can
      # depend on overlays such as rixpkgs-backed `pkgs.rpkgs`.
      default = nixpkgs.lib.composeManyExtensions [
        overlayDefs.dependencyOverlay
        (final: prev: {
          vv = (evalWithPkgs final []).config.wrap {pkgs = final;};
        })
      ];
      dependencies = overlayDefs.dependencyOverlay;
    };

    wrapperModules.default = module;
    wrapperConfigs.default = {pkgs, modules ? []}: (self.lib.eval {inherit pkgs modules;}).config;

    packages = forAllSystems (
      system: let
        pkgs = mkPkgs system;
      in {
        default = self.lib.mkWrapper {
          inherit pkgs;
        };
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
        config = (self.lib.eval {inherit pkgs;}).config;
        nvimPkg = config.wrap {inherit pkgs;};
      in {
        default = pkgs.mkShell {
          name = "vShell";
          packages = [nvimPkg] ++ self.lib.devShellPackages config;
          shellHook = mkShellHook config;
        };
      }
    );

    checks = forAllSystems (
      system: let
        pkgs = mkPkgs system;
        defaultConfig = (self.lib.eval {inherit pkgs;}).config;
        defaultNvimPkg = defaultConfig.wrap {inherit pkgs;};
        defaultShellHook = mkShellHook defaultConfig;
        overrideConfig =
          (self.lib.eval {
            inherit pkgs;
            modules = [
              {
                cats = {
                  r = false;
                  python = true;
                };
                settings.lang_packages.python = nixpkgs.lib.mkForce (with pkgs.python3Packages; [
                  pandas
                ]);
                catPkgs.nix = nixpkgs.lib.mkForce [
                  pkgs.alejandra
                ];
              }
            ];
          }).config;
        overrideShellHook = mkShellHook overrideConfig;
      in {
        default = pkgs.runCommand "check-vv" {} ''
          BINARY_PATH="${defaultNvimPkg}/bin/vv"

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
          _ = (self.lib.eval {inherit pkgs;}).config;
        in
          pkgs.runCommand "check-module-eval" {} ''
            echo "Module evaluation successful" > $out
          '';
        downstream-overrides = let
          overrideNix = builtins.map (p: p.pname or p.name) overrideConfig.catPkgs.nix;
          defaultAssertions = [
            (defaultConfig.cats.r or false)
            (builtins.match ".*R RHOME.*" defaultShellHook != null)
            (builtins.length (self.lib.devShellPackages defaultConfig) > 0)
          ];
          overrideAssertions = [
            (!(overrideConfig.cats.r or false))
            (builtins.length overrideNix == 1)
            ((builtins.head overrideNix) == "alejandra")
            (builtins.match ".*R RHOME.*" overrideShellHook == null)
          ];
        in
          pkgs.runCommand "check-downstream-overrides" {
            pass =
              if builtins.all (x: x) (defaultAssertions ++ overrideAssertions)
              then "1"
              else "";
          } ''
            if [ -z "$pass" ]; then
              echo "Downstream override assertions failed" >&2
              exit 1
            fi
            echo "Downstream override assertions passed" > $out
          '';
        lua-test = pkgs.runCommand "lua-test" {
          buildInputs = [ pkgs.neovim-unwrapped ];
        } ''
          nvim --headless -u NONE -c "set runtimepath+=${./.}" -l ${./tests/init.lua}
          touch $out
        '';

        smoke-test = pkgs.runCommand "smoke-test" {} ''
          BINARY_PATH="${defaultNvimPkg}/bin/vv"
          "$BINARY_PATH" --headless -c "luafile ${./tests/smoke.lua}" -c "qa!"
          touch $out
        '';
      }
    );

    nixosModules.default = wrappers.lib.getInstallModule {
      name = "vModule";
      value = module;
    };

    homeModules.default = wrappers.lib.getInstallModule {
      name = "vModule";
      value = module;
    };
  };
}
