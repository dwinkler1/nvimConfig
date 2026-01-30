{
  config,
  pkgs,
  lib,
  wlib,
  ...
}: {
  # ============================================================================
  # SPEC MODULE DEFAULTS
  # ============================================================================
  # Define default options available to all specs

  config.specMods = {parentSpec ? null, ...}: {
    options.extraPackages = lib.mkOption {
      type = lib.types.listOf wlib.types.stringable;
      default = [];
      description = "a extraPackages spec field to put packages to suffix to the PATH";
    };
  };

  # ============================================================================
  # EXTERNAL TOOLS SPEC
  # ============================================================================
  # Core system tools and utilities

  config.specs.external = {
    data = lib.mkDefault null;
    before = ["INIT_MAIN"];
    config = ''
      vim.o.shell = "${pkgs.zsh}/bin/zsh"
    '';
    runtimeDeps = "prefix";
    extraPackages = with pkgs; [
      perl
      ruby
      shfmt
      sqlfluff
      tree-sitter
    ];
  };

  # ============================================================================
  # OPTIONAL TOOLS SPEC
  # ============================================================================

  config.specs.optional = lib.mkIf (config.cats.optional or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    before = ["INIT_MAIN"];
    extraPackages = with pkgs; [
      bat
      broot
      devenv
      dust
      fd
      fzf
      gawk
      gh
      git
      hunspell
      hunspellDicts.de-at
      hunspellDicts.en-us
      ispell
      jq
      just
      lazygit
      man
      ncdu
      pigz
      poppler
      ripgrep
      tokei
      wget
      yq
      zathura
    ];
  };

  # ============================================================================
  # MARKDOWN SPEC
  # ============================================================================

  config.specs.markdown = lib.mkIf (config.cats.markdown or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    extraPackages = with pkgs; [
      python313Packages.pylatexenc
      quarto
      zk
    ];
  };

  # ============================================================================
  # NIX SPEC
  # ============================================================================

  config.specs.nix = lib.mkIf (config.cats.nix or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    extraPackages = with pkgs; [
      alejandra
      nix-doc
      nixd
    ];
  };

  # ============================================================================
  # LUA SPEC
  # ============================================================================

  config.specs.lua = lib.mkIf (config.cats.lua or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    extraPackages = with pkgs; [
      lua-language-server
    ];
  };

  # ============================================================================
  # PYTHON SPEC
  # ============================================================================

  config.specs.python = lib.mkIf (config.cats.python or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    extraPackages = let
      python_packages_fn =
        if pkgs ? basePythonPackages
        then ps: pkgs.basePythonPackages ps ++ config.settings.lang_packages.python
        else _: config.settings.lang_packages.python;
      python_with_packages = pkgs.python3.withPackages python_packages_fn;
    in
      with pkgs; [
        python_with_packages
        nodejs
        ruff
        basedpyright
        uv
      ];
  };

  # ============================================================================
  # R SPEC
  # ============================================================================

  config.specs.r = lib.mkIf (config.cats.r or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    extraPackages = let
      r_packages = (pkgs.baseRPackages or []) ++ config.settings.lang_packages.r;
    in
      with pkgs; [
        (rWrapper.override {packages = r_packages;})
        radianWrapper
        (quarto.override {extraRPackages = r_packages;})
        air-formatter
        yaml-language-server
        updateR
      ];
  };

  # ============================================================================
  # JULIA SPEC
  # ============================================================================

  config.specs.julia = lib.mkIf (config.cats.julia or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    extraPackages = let
      julia_with_packages =
        pkgs.julia-bin.withPackages config.settings.lang_packages.julia;
    in [julia_with_packages];
  };

  # ============================================================================
  # CLICKHOUSE SPEC
  # ============================================================================

  config.specs.clickhouse = lib.mkIf (config.cats.clickhouse or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    extraPackages = with pkgs; [
      clickhouse-lts
    ];
  };

  config.extraPackages = config.specCollect (acc: v: acc ++ (v.extraPackages or [])) [];
}
