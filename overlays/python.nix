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
}
