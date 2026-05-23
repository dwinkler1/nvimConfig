{
  config,
  pkgs,
  lib,
  ...
}:
let
  maybe = cat: pkgsList:
    lib.optionals (config.cats.${cat} or false) pkgsList;
  rPackages = (pkgs.baseRPackages or [ ]) ++ config.settings.lang_packages.r;
  rWrapperPackages = rPackages;
  quartoPkg =
    if config.cats.r or false
    then pkgs.rpkgs.quarto.override { extraRPackages = rPackages; }
    else pkgs.quarto;
in
{
  options.catPkgs = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.package);
    description = "Per-cat package lists, gated by cat toggles. Single source of truth for runtimeDeps and devShells.";
  };

  config.catPkgs = {
    always = maybe "always" (with pkgs; [ ]);

    clickhouse = maybe "clickhouse" (with pkgs; [ clickhouse-lts ]);

    external = maybe "external" (with pkgs; [
      perl
      ruby
      shfmt
      sqlfluff
      tree-sitter
    ]);

    julia = maybe "julia" [
      (pkgs.julia-bin.withPackages config.settings.lang_packages.julia)
    ];

    lua = maybe "lua" (with pkgs; [ lua-language-server ]);

    markdown = maybe "markdown" (with pkgs; [
      python313Packages.pylatexenc
      quartoPkg
      zk
    ]);

    nix = maybe "nix" (with pkgs; [
      alejandra
      nix-doc
      nixd
    ]);

    optional = maybe "optional" (with pkgs; [
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
    ]);

    python = maybe "python" (let
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
      ]);

    r = maybe "r" [
      (pkgs.rpkgs.rWrapper.override { packages = rWrapperPackages; })
      pkgs.rpkgs.radianWrapper
      quartoPkg
      pkgs.air-formatter
      pkgs.yaml-language-server
      pkgs.rnvimserver
    ];

    # cats without packages get empty lists
    general = [ ];
    gitPlugins = [ ];
    treesitterParsers = [ pkgs.tree-sitter ];
    utils = [ ];
  };
}
