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
      evalResult = nvimConfig.lib.eval {
        inherit pkgs;
        modules = [ projectSettings ];  # see below
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
      evalResult = nvimConfig.lib.eval {
        inherit pkgs;
        modules = [ projectSettings ];
      };
      nv = evalResult.config.wrap { inherit pkgs; };
    in {
      default = pkgs.mkShell {
        packages = [ nv ] ++ nvimConfig.lib.devShellPackages evalResult.config;
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

Define a `projectSettings` attrset and pass it to `nvimConfig.lib.eval` or `nvimConfig.lib.mkWrapper`. The helper injects your overlaid `pkgs` automatically, so downstream consumers do not need to wire `specialArgs` themselves. Every option in `nvimConfig.wrapperConfigs.default` can be overridden here. Local `packages.default`, local `devShells.default`, downstream helper usage, and `pkgs.vv` all resolve the same module defaults unless you override them.

### Basic downstream flake example

This example enables a few cats, adds runtime tools to the shared wrapper/devShell package set, and appends language libraries to the default Python and R environments.

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

  outputs = { nixpkgs, nvimConfig, ... }: let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ nvimConfig.overlays.dependencies ];
    };
    projectSettings = {
      cats = {
        python = true;
        r = true;
        nix = true;
        markdown = true;
        optional = true;
      };

      settings.lang_packages = {
        python = with pkgs.python3Packages; [
          pandas
          pyarrow
        ];
        r = with pkgs.rpkgs.rPackages; [
          fixest
          modelsummary
        ];
      };

      catPkgs = {
        python = [
          (pkgs.python3.withPackages (ps:
            ps
            ++ (with ps; [
              pandas
              pyarrow
            ])))
          pkgs.ruff
          pkgs.basedpyright
          pkgs.uv
          pkgs.nodejs
        ];
        nix = [
          pkgs.alejandra
          pkgs.nil
        ];
        optional = [
          pkgs.git
          pkgs.fd
          pkgs.ripgrep
        ];
      };
    };
    evalResult = nvimConfig.lib.eval {
      inherit pkgs;
      modules = [ projectSettings ];
    };
    nv = evalResult.config.wrap { inherit pkgs; };
  in {
    packages.${system}.default = nv;

    devShells.${system}.default = pkgs.mkShell {
      packages = [ nv ] ++ nvimConfig.lib.devShellPackages evalResult.config;
    };
  };
}
```

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

### Language packages (module defaults)

Add Python/R/Julia libraries that get appended to the module defaults. The built-in defaults are:

- Python: `duckdb`, `polars`
- R: `arrow`, `broom`, `data_table`, `janitor`, `styler`, `nvimcom`
- Julia: `DataFramesMeta`, `QuackIO`

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

Override `catPkgs` to change the full runtime tool lists that appear in both the wrapper PATH and the devShell. Use normal assignments to merge list values, or `lib.mkForce` to replace them.

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

### Choosing the right override surface

- Use `cats` to enable or disable a whole language or tooling category.
- Use `settings.lang_packages` to add or replace Python, R, or Julia libraries within a language environment.
- Use `catPkgs` to change the full runtime tool list for a category. `config.runtimePkgs` drives wrapper PATH composition, while `nvimConfig.lib.devShellPackages config` returns the package-only list suitable for `mkShell`.
- Use `env` or `envDefault` for wrapper environment variables.
- Use `specs` for plugin additions or custom runtime behavior.

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
settings/lang-packages.nix ──► settings.lang_packages
                                             │
cats.nix ───────────────► config.cats        │
                     │                       │
                     ▼                       ▼
             cat-packages.nix ───────► config.catPkgs.<cat>
                     │                       │
                     ├──────────────┐        │
                     ▼              ▼        ▼
             deps.nix PATH     wrapper.config.wrap   devShells.default
```

- **Overlays** (`overlays/`) inject dependency package sets into nixpkgs (`rpkgs`, `baseRPackages`, `basePythonPackages`, plugins). Top-level `rWrapper` and `quarto` are compatibility conveniences, but `pkgs.rpkgs` is the canonical R surface for downstream configuration.
- **cat-packages.nix** is the single source of truth for per-category packages. Each list is gated by its cat toggle.
- **deps.nix** wires `catPkgs` into the wrapper's runtime PATH.
- **settings.lang_packages** holds the shared defaults used by local outputs and downstream module consumers.
- **flake.nix** exports `lib.eval`, `lib.mkWrapper`, and `lib.devShellPackages` as the canonical downstream helpers, and builds `packages.default` and `devShells.default` from the same module config.
