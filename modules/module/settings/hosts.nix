{
  config,
  pkgs,
  lib,
  ...
}:
let
  rPackages = (pkgs.baseRPackages or [ ]) ++ config.settings.lang_packages.r;
  rWrapperPkg = pkgs.rpkgs.rWrapper.override { packages = rPackages ++ [pkgs.nvimcom]; };
in
{
  config.hosts = lib.mkMerge [
    {
      node.nvim-host.enable = true;
      perl.nvim-host.enable = true;
      ruby.nvim-host.enable = true;

      g = {
        nvim-host.enable = true;
        nvim-host.package = "${pkgs.neovide}/bin/neovide";
        nvim-host.argv0 = "neovide";
        nvim-host.flags."--neovim-bin" = "${builtins.placeholder "out"}/bin/${config.binName}";
      };

    }
    (lib.mkIf (config.cats.julia or false) {
      jl = {
        nvim-host.enable = true;
        nvim-host.package = "${pkgs.julia-bin}/bin/julia";
        nvim-host.argv0 = "julia";
        nvim-host.addFlag = [
          "--project=@."
        ];
      };
    })
    (lib.mkIf (config.cats.python or false) {
      python3.nvim-host.enable = true;
    })
    (lib.mkIf (config.cats.r or false) {
      r = {
        nvim-host.enable = true;
        nvim-host.package = "${rWrapperPkg}/bin/R";
        nvim-host.argv0 = "R";
        nvim-host.addFlag = [
          "--no-save"
          "--no-restore"
        ];
      };
    })
  ];
}
