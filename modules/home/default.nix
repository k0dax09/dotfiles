# modules/home — aggregator for home-manager modules (programs, services, etc.).
#
# Add user-level modules here. Each host's home.nix imports this aggregator.
{ ... }:
{
  imports = [
    # ./programs/git.nix
    # ./programs/shell.nix
  ];
}
