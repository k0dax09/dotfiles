# Overlay that injects the `helium` package from this repo.
# Sourced into flake.nix so `pkgs.helium` resolves even if it's absent in nixpkgs.
# If nixpkgs already ships `helium`, you can drop this overlay entirely.

final: prev:
{
  helium = final.callPackage ./package.nix { };
}