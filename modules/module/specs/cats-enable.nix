{ config, lib, ... }:
{
  # This module implements category-based enabling of specs.
  # It runs early (order 200) so other specMaps can see the enable flags.
  #
  # How it works:
  # 1. For each spec, extract its name (removing -lazy suffix if present)
  # 2. Check if there's a corresponding cats.<name> toggle
  # 3. Set spec.value.enable based on the cats toggle (default: true)
  # 4. This allows specs to be conditionally included based on config.cats settings
  #
  # Example: If config.cats.python = false, then specs.python.enable = false

  config.specMaps = lib.mkOrder 200 [
    {
      name = "CATS_ENABLE";
      data =
        list:
        map (
          v:
          if v.type == "spec" || v.type == "parent" then
            let
              # Extract spec name, handling lazy specs (remove -lazy suffix)
              specName =
                if v.name == null then
                  null
                else if lib.hasSuffix "-lazy" v.name then
                  lib.removeSuffix "-lazy" v.name
                else
                  v.name;

              # Check if this spec has a corresponding cat toggle
              catEnabled =
                if specName != null && builtins.hasAttr specName config.cats then
                  config.cats.${specName}
                else
                  true;  # Default to enabled if no cat toggle exists
            in
            v
            // {
              value = v.value // {
                # Use explicit enable if set, otherwise use cat toggle
                enable = if v.value ? enable then v.value.enable else catEnabled;
              };
            }
          else
            v
        ) list;
    }
  ];
}
