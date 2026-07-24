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
    # R.nvim v1.x owns its cache and temporary directories and exports
    # RNVIM_COMPLDIR/RNVIM_TMPDIR during setup. Do not inject literal `$PWD`
    # values into the wrapper environment.
  ];

  # Environment variables with defaults (can be overridden by user)
  config.envDefault = lib.mkMerge [ ];
}
