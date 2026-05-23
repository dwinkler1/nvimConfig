{
  inputs,
  ...
}: final: prev: let
  rpkgs = import inputs.rixpkgs {
    system = prev.stdenv.hostPlatform.system;
    overlays = [inputs.fran.overlays.default];
  };
in {
  inherit rpkgs;
  baseRPackages = [ ];
  rWrapper = rpkgs.rWrapper.override {packages = [ ];};
  quarto = rpkgs.quarto.override {extraRPackages = [ ];};
}
