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

  config.specs.always = lib.mkIf (config.cats.always or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.always;
  };

  config.specs.external = lib.mkIf (config.cats.external or false) {
    data = lib.mkDefault null;
    before = ["INIT_MAIN"];
    config = ''
      vim.o.shell = "${pkgs.zsh}/bin/zsh"
    '';
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.external;
  };

  config.specs.optional = lib.mkIf (config.cats.optional or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    before = ["INIT_MAIN"];
    runtimePkgs = config.catPkgs.optional;
  };

  config.specs.markdown = lib.mkIf (config.cats.markdown or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.markdown;
  };

  config.specs.nix = lib.mkIf (config.cats.nix or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.nix;
  };

  config.specs.lua = lib.mkIf (config.cats.lua or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.lua;
  };

  config.specs.python = lib.mkIf (config.cats.python or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.python;
  };

  config.specs.r = lib.mkIf (config.cats.r or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.r;
  };

  config.specs.julia = lib.mkIf (config.cats.julia or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.julia;
  };

  config.specs.clickhouse = lib.mkIf (config.cats.clickhouse or false) {
    data = lib.mkDefault null;
    runtimeDeps = "prefix";
    runtimePkgs = config.catPkgs.clickhouse;
  };

  config.runtimePkgs = config.specCollect (acc: v: acc ++ (v.runtimePkgs or [])) [];
}
