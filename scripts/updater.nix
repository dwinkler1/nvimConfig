{pkgs}:
pkgs.writeShellApplication {
  name = "updateR";

  # Tools your script needs at runtime
  runtimeInputs = [
    pkgs.wget
    pkgs.gnused
    pkgs.coreutils
  ];

  # Keep script in separate file, but embed contents
  text = builtins.readFile ./updater.sh;
}
