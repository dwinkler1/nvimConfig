{ nixpkgs, ... }@inputs:
let
  lib = nixpkgs.lib;

  rOverlay = import ./r.nix {inherit inputs;};
  rNvimNixOverlay = inputs.r-nvim-nix.overlays.default;
  franOverlay = inputs.fran.overlays.default;
  pythonOverlay = import ./python.nix inputs;
  pluginsOverlay = import ./plugins.nix inputs;

  dependencyOverlays = [
    rOverlay
    rNvimNixOverlay
    pythonOverlay
    pluginsOverlay
  ];
  dependencyOverlay = lib.composeManyExtensions dependencyOverlays;
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

  # Named exports for downstream composition.
  default = dependencyOverlay;
  dependencies = dependencyOverlays;

  overlays = {
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
  };
}
