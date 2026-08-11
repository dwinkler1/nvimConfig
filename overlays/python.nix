{ ... }:
final: prev:
let
  reqPkgs = pyPackages:
    with pyPackages; [
      numpy
    ];
in
{
  basePythonPackages = reqPkgs;
  python = prev.python3.withPackages reqPkgs;

  # pyarrow's test_timezone_absent reads /usr/share/zoneinfo, which is
  # blocked by the build sandbox (PermissionError: Operation not permitted).
  python3Packages = prev.python3Packages // {
    pyarrow = prev.python3Packages.pyarrow.overridePythonAttrs (old: {
      disabledTests = (old.disabledTests or [ ]) ++ [
        "pyarrow/tests/test_orc.py::test_timezone_absent"
      ];
    });
  };
}