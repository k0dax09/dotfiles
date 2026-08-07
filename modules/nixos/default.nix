# modules/nixos — aggregator for all NixOS system modules.
#
# Adding a new system service? Drop the file in ./services/*.nix and list it
# here once — hosts don't need to know the file path, they just import this.
{
  imports = [
    ./services/anirevpn.nix
    ./services/browsers.nix
    ./services/lock.nix
    ./services/login.nix
    ./services/tor.nix
    ./services/virtualisation.nix
  ];
}
