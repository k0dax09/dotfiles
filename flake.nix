{
  description = "niri dotfiles — NixOS + home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:YaLTeR/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      niri,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      overlays = [
        (import ./pkgs/helium/overlay.nix)
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
      };

      hosts = builtins.filter
        (
          name:
          builtins.pathExists (
            ./hosts + "/${name}/default.nix"
          )
        )
        (builtins.attrNames (builtins.readDir ./hosts));

      nixosConfig =
        hostName:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs overlays;
          };

          modules = [
            { nixpkgs.overlays = overlays; }

            (./hosts + "/${hostName}/default.nix")

            home-manager.nixosModules.home-manager

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.extraSpecialArgs = {
                inherit inputs overlays;
              };

              home-manager.users.user =
                import (./home + "/${hostName}/home.nix");
            }
          ];
        };

      homeConfig =
        hostName:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          extraSpecialArgs = {
            inherit inputs overlays;
          };

          modules = [
            (./home + "/${hostName}/home.nix")
          ];
        };
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map
          (
            name: {
              inherit name;
              value = nixosConfig name;
            }
          )
          hosts
      );

      homeConfigurations = builtins.listToAttrs (
        map
          (
            name: {
              inherit name;
              value = homeConfig name;
            }
          )
          hosts
      );

      # formatter.<system> — вложенный атрибут, а не буквальное имя.
      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
