{
  config,
  pkgs,
  lib,
  ...
}: {
  # Environment variables set for the wrapper.
  # These are available when running neovim.
  config.env = lib.mkMerge [
    (lib.mkIf (config.cats.python or true) {
      UV_PYTHON_DOWNLOADS = "never";
      UV_PYTHON = pkgs.python.interpreter;
    })
    (lib.mkIf (config.cats.r or true) {
      RNVIM_COMPLDIR = "$PWD/.r-compl";
      R_LIBS_USER = "${pkgs.nvimcom}/library:$PWD/.Rlibs";
      TMPDIR = "$PWD/.r-tmp";
    })
  ];

  # Environment variables with defaults (can be overridden by user)
  config.envDefault = lib.mkMerge [
    (lib.mkIf (config.cats.r or true) {
      R_LIBS_USER = "${pkgs.nvimcom}/library:$PWD/.Rlibs";
    })
  ];
}
