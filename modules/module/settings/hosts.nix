{
  config,
  pkgs,
  lib,
  ...
}:
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
        nvim-host.flags."--neovim-bin" = "${placeholder "out"}/bin/${config.binName}";
      };

      m = {
        nvim-host.enable = false;
        nvim-host.package = "${pkgs.uv}/bin/uv";
        nvim-host.argv0 = "uv";
        nvim-host.addFlag = [
          "run"
          "marimo"
          "edit"
        ];
      };
    }
    (lib.mkIf (config.cats.julia or true) {
      jl = {
        nvim-host.enable = true;
        nvim-host.package = "${pkgs.julia-bin}/bin/julia";
        nvim-host.argv0 = "julia";
        nvim-host.addFlag = [
          "--project=@."
        ];
      };
    })
    (lib.mkIf (config.cats.python or true) {
      python3.nvim-host.enable = true;
    })
    (lib.mkIf (config.cats.r or true) {
      r = {
        nvim-host.enable = true;
        nvim-host.package = "${pkgs.rWrapper}/bin/R";
        nvim-host.argv0 = "R";
        nvim-host.addFlag = [
          "--no-save"
          "--no-restore"
        ];
      };
    })
  ];
}
