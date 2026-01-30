{
  config,
  pkgs,
  lib,
  ...
}: {
  # Environment variables set for the wrapper.
  # These are available when running neovim.
  config.env = lib.mkMerge [
    (lib.mkIf (config.cats.python or false) {
      UV_PYTHON_DOWNLOADS = "never";
      UV_PYTHON = pkgs.python.interpreter;
    })
  ];

  # Environment variables with defaults (can be overridden by user)
  config.envDefault = lib.mkMerge [
    (lib.mkIf (config.cats.r or false) {
      R_LIBS_USER =  "./.Rlibs";
    })
  ];
}
