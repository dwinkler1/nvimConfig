{ nixpkgs, ... }@inputs:
let
  lib = nixpkgs.lib;

  rOverlay = import ./r.nix inputs;
  franOverlay = inputs.fran.overlays.default;
  pythonOverlay = import ./python.nix inputs;
  pluginsOverlay = import ./plugins.nix inputs;

  dependencyOverlays = [
    rOverlay
    franOverlay
    pythonOverlay
    pluginsOverlay
  ];
  dependencyOverlay = lib.composeManyExtensions dependencyOverlays;
in
{
  inherit
    rOverlay
    franOverlay
    pythonOverlay
    pluginsOverlay
    dependencyOverlays
    dependencyOverlay;

  # Named exports for downstream composition.
  default = dependencyOverlay;
  dependencies = dependencyOverlays;

  overlays = {
    inherit
      rOverlay
      franOverlay
      pythonOverlay
      pluginsOverlay
      dependencyOverlays
      dependencyOverlay;
    default = dependencyOverlay;
    dependencies = dependencyOverlays;
  };
}
