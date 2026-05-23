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
      - always: always-on packages (not gated by a toggle)
      - clickhouse: Clickhouse client and tools
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
      - treesitterParsers: Treesitter parsers
      - utils: general utilities
    '';
  };

  config.cats = {
    always = lib.mkDefault true;
    clickhouse = lib.mkDefault false;
    external = lib.mkDefault true;
    general = lib.mkDefault true;
    gitPlugins = lib.mkDefault true;
    julia = lib.mkDefault false;
    lua = lib.mkDefault true;
    markdown = lib.mkDefault true;
    nix = lib.mkDefault true;
    optional = lib.mkDefault false;
    python = lib.mkDefault false;
    r = lib.mkDefault true;
    treesitterParsers = lib.mkDefault true;
    utils = lib.mkDefault true;
  };
}
