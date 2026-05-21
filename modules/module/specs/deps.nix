{
  config,
  pkgs,
  lib,
  wlib,
  ...
}: {
  config.specMods = {parentSpec ? null, ...}: {
    options.runtimePkgs = lib.mkOption {
      type = lib.types.listOf wlib.types.stringable;
      default = [];
      description = "a runtimePkgs spec field to put packages to suffix to the PATH";
    };
  };

  config.specs.external = {
    data = lib.mkDefault null;
    before = ["INIT_MAIN"];
    config = ''
      vim.o.shell = "${pkgs.zsh}/bin/zsh"
    '';
    runtimeDeps = "prefix";
    runtimePkgs = with pkgs; [
      perl
      ruby
      shfmt
      sqlfluff
      tree-sitter
    ];
  };

  config.specs.optional = lib.mkIf (config.cats.optional or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    before = ["INIT_MAIN"];
    runtimePkgs = with pkgs; [
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

  config.specs.markdown = lib.mkIf (config.cats.markdown or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = with pkgs; [
      python313Packages.pylatexenc
      quarto
      zk
    ];
  };

  config.specs.nix = lib.mkIf (config.cats.nix or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = with pkgs; [
      alejandra
      nix-doc
      nixd
    ];
  };

  config.specs.lua = lib.mkIf (config.cats.lua or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = with pkgs; [
      lua-language-server
    ];
  };

  config.specs.python = lib.mkIf (config.cats.python or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = let
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

  config.specs.r = lib.mkIf (config.cats.r or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = let
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

  config.specs.julia = lib.mkIf (config.cats.julia or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = let
      julia_with_packages =
        pkgs.julia-bin.withPackages config.settings.lang_packages.julia;
    in [julia_with_packages];
  };

  config.specs.clickhouse = lib.mkIf (config.cats.clickhouse or true) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = with pkgs; [
      clickhouse-lts
    ];
  };

  config.runtimePkgs = config.specCollect (acc: v: acc ++ (v.runtimePkgs or [])) [];
}
