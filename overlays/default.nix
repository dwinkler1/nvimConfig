{ nixpkgs, ... }@inputs:
let
  lib = nixpkgs.lib;

  rOverlay = import ./r.nix {inherit inputs;};
  rNvimNixOverlay = inputs.r-nvim-nix.overlays.default;
  pythonOverlay = import ./python.nix {inherit inputs;};
  pluginsOverlay = import ./plugins.nix {inherit inputs;};

  dependencyOverlays = [
    rOverlay
    rNvimNixOverlay
    pythonOverlay
    pluginsOverlay
  ];
  dependencyOverlay = lib.composeManyExtensions dependencyOverlays;

  # franOverlay provides R-specific tooling (radianWrapper, air-formatter).
  # It is scoped to rixpkgs (via overlays/r.nix) rather than the global
  # package set, since it only applies to R package derivations.
  franOverlay = inputs.fran.overlays.default;
in
{
  inherit
    rOverlay
    rNvimNixOverlay
    franOverlay
    pythonOverlay
    pluginsOverlay
    dependencyOverlays
    dependencyOverlay;

  default = dependencyOverlay;
  dependencies = dependencyOverlays;
}
