# nvimConfig

Modular Neovim wrapper config. Defines a wrapped `vv` binary with per-category packages, plugins, and environment variables. Available as NixOS module, Home Manager module, or single-starflake import.

## Quick start (imported into another flake)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rixpkgs.url = "github:dwinkler1/rixpkgs/af2dd3f7b4b172077747c0869d4e30702fb71b0e";
    fran = {
      url = "github:dwinkler1/fran";
      inputs.nixpkgs.follows = "rixpkgs";
    };
    nvimConfig = {
      url = "github:dwinkler1/nvimConfig";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rixpkgs.follows = "rixpkgs";
        fran.follows = "fran";
      };
    };
  };

  outputs = { self, nixpkgs, nvimConfig, ... } @ inputs: let
    systems = ["aarch64-darwin" "x86_64-linux" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nvimConfig.overlays.dependencies ];
      };
      evalResult = nvimConfig.inputs.wrappers.lib.evalModules {
        modules = [
          nvimConfig.wrapperModules.default
          projectSettings  # see below
        ];
      };
    in {
      default = evalResult.config.wrap { inherit pkgs; };
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nvimConfig.overlays.dependencies ];
      };
      evalResult = nvimConfig.inputs.wrappers.lib.evalModules {
        modules = [
          nvimConfig.wrapperModules.default
          projectSettings
        ];
      };
      nv = evalResult.config.wrap { inherit pkgs; };
    in {
      default = pkgs.mkShell {
        packages =
          [ nv ]
          ++ (evalResult.config.catPkgs.markdown or [])
          ++ (evalResult.config.catPkgs.nix or []);
      };
    });
  };
}
```

## Home Manager module

```nix
{ inputs, ... }: {
  home.packages = [
    (inputs.nvimConfig.homeModules.default { inherit pkgs; })
    # Or via the overlay:
    # pkgs.vv
  ];
}
```

## NixOS module

```nix
{ inputs, ... }: {
  environment.systemPackages = [
    (inputs.nvimConfig.nixosModules.default { inherit pkgs; })
  ];
}
```

## Overriding settings

Define a `projectSettings` attrset and pass it as the second module in `evalModules`. Every option in `nvimConfig.wrapperConfigs.default` can be overridden here.

### Categories

Enable only the cats you need. Defaults are listed in `modules/module/settings/cats.nix`.

```nix
projectSettings = {
  cats = {
    python = true;       # enable Python tooling
    r = false;           # disable R
    nix = true;
    lua = false;
    markdown = false;
    optional = false;
    gitPlugins = false;
  };
};
```

### Language packages (overlay extension)

Add Python/R/Julia libraries that get appended to the overlay base packages.

```nix
projectSettings = {
  settings.lang_packages = {
    python = with pkgs.python3Packages; [ pandas numpy ];
    r = with pkgs.rpkgs.rPackages; [ fixest data_table ];
    julia = [ "StatsBase" "Plots" ];
  };
};
```

Use `lib.mkForce` to replace rather than append:

```nix
projectSettings = {
  settings.lang_packages = {
    python = pkgs.lib.mkForce (with pkgs.python3Packages; [ polars duckdb ]);
  };
};
```

### Runtime dependencies (per-cat packages)

Override `catPkgs` to add tools that appear in both the wrapper PATH and the devShell. To add always-available packages not gated by any cat, use `runtimePkgs` directly (see next section).

```nix
projectSettings = {
  catPkgs = {
    nix = [ pkgs.nil pkgs.nixfmt ];
    python = [
      (pkgs.python3.withPackages (ps: [ ps.pandas ps.duckdb ]))
      pkgs.ruff
    ];
  };
};
```

### Direct runtimePkgs override (always-on)

Add packages to `catPkgs.always` for tools that should always be available regardless of other cat toggles.

```nix
projectSettings = {
  catPkgs = {
    always = [ pkgs.git pkgs.curl pkgs.pre-commit ];
  };
};
```

### Runtime env vars

```nix
projectSettings = {
  env = {
    MY_PROJECT_VAR = "some-value";
  };
  envDefault = {
    EDITOR = "vv";
  };
};
```

`env` values are forced; `envDefault` values can be overridden by the user's shell.

### Neovim settings

```nix
projectSettings = {
  settings = {
    colorscheme = "kanagawa";
    background = "dark";
    wrapRc = true;
    config_directory = ./nvim;  # path to init.lua + lua/ dir
    aliases = [ "v" "nvim" ];   # extra binary names (default: [ "vvim" ])
  };
  binName = "nv";               # binary name (default: vv)
};
```

## Adding plugins

```nix
projectSettings = {
  specs = {
    extraPlugins = {
      data = with pkgs.vimPlugins; [
        telescope-nvim
        which-key-nvim
      ];
    };

    extraLazy = {
      lazy = true;
      data = with pkgs.vimPlugins; [ dashboard-nvim ];
    };

    # Inject Lua config at startup
    extraLua = {
      data = pkgs.writeText "extra.lua" ''
        vim.opt.number = true
        vim.opt.relativenumber = true
      '';
      before = ["INIT_MAIN"];
    };
  };
};
```

## Architecture

```
langPackages (flake.nix) ──► settings.lang_packages (module option)
                                        │
cats.nix ──► config.cats                │
                  │                     │
                  ▼                     ▼
          cat-packages.nix ──► config.catPkgs.<cat>
                  │                     │
          ┌───────┘                     │
          ▼                             ▼
   deps.nix (runtimePkgs)       flake.nix (devShells)
          │                             │
          ▼                             ▼
   wrapped vv PATH              nix develop PATH
```

- **Overlays** (`overlays/`) inject base packages into nixpkgs (rWrapper, quarto, baseRPackages, basePythonPackages).
- **cat-packages.nix** is the single source of truth for per-category packages. Each list is gated by its cat toggle.
- **deps.nix** wires `catPkgs` into the wrapper's runtime PATH.
- **flake.nix** reads `catPkgs` for the devShell. `langPackages` feeds into `settings.lang_packages`.
