# R packages overlay (rix)
#
# This overlay provides access to R packages from rstats-on-nix.
#
# rstats-on-nix maintains snapshots of CRAN packages built with Nix:
# - Provides reproducible R package versions
# - Ensures binary cache availability for faster builds
# - Maintained by the rstats-on-nix community
#
# Available attributes after applying this overlay:
#   - pkgs.rpkgs: R packages from rstats-on-nix
#   - pkgs.rpkgs.rPackages: All CRAN packages
#   - pkgs.rpkgs.quarto: Quarto publishing system
#   - pkgs.rpkgs.rWrapper: R with package management
#   - pkgs.rWrapper: R wrapper with standard packages pre-configured
#   - pkgs.quarto: Quarto with R integration and standard packages
#
# Custom R packages and tools (radianWrapper, air-formatter) come from
# the fran overlay which should be applied separately.
#
# To use specific R packages, reference them via:
#   with pkgs.rpkgs.rPackages; [ package1 package2 ]
#
# Update the R snapshot date in flake.nix inputs section:
#   rixpkgs.url = "github:rstats-on-nix/nixpkgs/YYYY-MM-DD"
{rixpkgs, ...}: final: prev: let
  # R packages from rstats-on-nix for the current system
  rpkgs = rixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system};

  # Standard R packages used by default in rWrapper and quarto
  reqPkgs = with rpkgs.rPackages; [
    languageserver
  ];
in {
  inherit rpkgs;
  baseRPackages = reqPkgs;

  # R wrapper with standard packages
  rWrapper = rpkgs.rWrapper.override {packages = reqPkgs;};

  # Quarto with R integration
  quarto = rpkgs.quarto.override {extraRPackages = reqPkgs;};

  # Update helper for rix
  updateR = import ../scripts/updater.nix { pkgs = final; };
}
