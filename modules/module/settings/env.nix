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
    #
    # ponytail: with R_LIBS_USER unset-or-empty, loading compiled namespaces
    # (S7 via btw) segfaults on macOS for bare-terminal launches outside the
    # devShell hook. Any non-empty value avoids it; this store path exists,
    # contains no libraries, and stays inert. The devShell hook overrides it
    # with $PWD/.r-libs. Upgrade path: teach wlib to emit expandable defaults.
    (lib.mkIf (config.cats.r or false) {
      R_LIBS_USER = "${pkgs.rpkgs.rWrapper}";
    })
  ];

  # Environment variables with defaults (can be overridden by user)
  config.envDefault = lib.mkMerge [ ];
}
