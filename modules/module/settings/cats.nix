{
  config,
  lib,
  ...
}:
{
  options.cats = lib.mkOption {
    type = lib.types.attrsOf lib.types.bool;
    description = ''
      Category toggles used to enable/disable specs by name.

      Keys map directly to specs (e.g., `python` controls `specs.python`).
      Set a category to `false` to skip its dependency/plugin specs.

      Available categories:
      - clickhouse: Clickhouse client and tools
      - customPlugins: local plugin specs
      - external: external tools and integrations
      - general: core Neovim plugins/features
      - gitPlugins: git-related plugins
      - julia: Julia tooling and packages
      - lua: Lua tooling and LSPs
      - markdown: markdown tooling and plugins
      - nix: Nix tooling and plugins
      - optional: optional tools and utilities
      - python: Python tooling and plugins
      - r: R tooling and plugins
      - test: test-only tooling (disabled by default)
      - treesitterParsers: Treesitter parsers
      - utils: general utilities
    '';
  };

  config.cats = {
    clickhouse = lib.mkDefault false;
    customPlugins = lib.mkDefault true;
    external = lib.mkDefault true;
    general = lib.mkDefault true;
    gitPlugins = lib.mkDefault true;
    julia = lib.mkDefault false;
    lua = lib.mkDefault false;
    markdown = lib.mkDefault false;
    nix = lib.mkDefault false;
    optional = lib.mkDefault false;
    python = lib.mkDefault false;
    r = lib.mkDefault false;
    test = lib.mkDefault false;
    treesitterParsers = lib.mkDefault true;
    utils = lib.mkDefault true;
  };
}
