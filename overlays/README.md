# Overlays

This directory contains composable Nix overlays used by the Neovim wrapper configuration. Each overlay is small and focused, so you can reuse or override them downstream.

## Files

- `r.nix`  
  R-related overrides (rix overlay). Exposes `pkgs.rpkgs` from rstats-on-nix and creates pre-configured `rWrapper` and `quarto` with standard R packages.

- `python.nix`  
  Python-related overrides and package additions (e.g., extra Python packages).

- `plugins.nix`  
  Neovim plugin overrides (e.g., patching or pinning plugin derivations).

- `default.nix`  
  Aggregates and exports the overlays in a composable way. Includes the fran overlay for custom R packages.

## Exports from `default.nix`

`overlays/default.nix` exposes:

- `rOverlay` - rix overlay for R packages from rstats-on-nix
- `franOverlay` - fran overlay for custom R packages and tools  
- `pythonOverlay`  
- `pluginsOverlay`  
- `dependencyOverlays` (list of overlays in order)  
- `dependencyOverlay` (composed overlay via `lib.composeManyExtensions`)  
- `default` (alias of `dependencyOverlay`)  
- `dependencies` (alias of `dependencyOverlays`)

## Downstream usage examples

### Use the composed default overlay

```/dev/null/example.nix#L1-18
{
  inputs,
  ...
}:
let
  overlayDefs = import ./overlays/default.nix inputs;
in {
  nixpkgs.overlays = [
    overlayDefs.default
  ];
}
```

### Use specific overlays only

```/dev/null/example.nix#L1-22
{
  inputs,
  ...
}:
let
  overlayDefs = import ./overlays/default.nix inputs;
in {
  nixpkgs.overlays = [
    overlayDefs.rOverlay
    overlayDefs.pluginsOverlay
  ];
}
```

### Extend with your own overlay (composition)

```/dev/null/example.nix#L1-29
{
  inputs,
  ...
}:
let
  overlayDefs = import ./overlays/default.nix inputs;
  myOverlay = final: prev: {
    # Example: override a package
    myTool = prev.myTool.override { /* ... */ };
  };
in {
  nixpkgs.overlays = [
    overlayDefs.default
    myOverlay
  ];
}
```

## Adding a new overlay

1. Create a new overlay file in this directory (e.g., `foo.nix`).
2. Import it in `overlays/default.nix` and add it to `dependencyOverlays`.
3. Optionally expose it as a named export (e.g., `fooOverlay`) for downstream reuse.

## Notes

- Keep overlays composable and focused.
- Avoid monolithic overlays; prefer small, purpose-specific overlays.
- When overriding plugins, keep patches minimal and document the intent.