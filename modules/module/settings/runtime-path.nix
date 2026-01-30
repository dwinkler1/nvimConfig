{
  config,
  lib,
  ...
}:
let
  collect_runtime_packages = runtime_deps_type:
    config.specCollect
      (acc: spec:
        let
          is_enabled = if spec ? enable then spec.enable else true;
          has_runtime_deps = (spec.runtimeDeps or false) == runtime_deps_type;
          packages = spec.extraPackages or [ ];
        in
        acc ++ lib.optionals (is_enabled && has_runtime_deps) packages
      )
      [ ];

  prefix_packages = collect_runtime_packages "prefix";
  suffix_packages = collect_runtime_packages "suffix";

  to_path_specs = packages: [
    {
      data = [
        "PATH"
        ":"
        "${lib.makeBinPath packages}"
      ];
    }
  ];
in
{
  config.prefixVar = lib.optionals (prefix_packages != [ ]) (to_path_specs prefix_packages);
  config.suffixVar = lib.optionals (suffix_packages != [ ]) (to_path_specs suffix_packages);
}
