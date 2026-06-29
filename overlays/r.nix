{inputs, ...}: final: prev: let
  rpkgs = import inputs.rixpkgs {
    system = prev.stdenv.hostPlatform.system;
    overlays = [inputs.fran.overlays.default inputs.r-nvim-nix.overlays.default];
  };
in {
  inherit rpkgs;
  baseRPackages = [rpkgs.nvimcom];
  rWrapper = rpkgs.rWrapper.override {packages = [];};
  quarto = rpkgs.quarto.override {extraRPackages = [];};
}
