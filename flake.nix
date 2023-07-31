{
  description = "NixOS Flake: Desktop PC, VPS, laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager }:
  let
    system = "x86_64-linux";
  in 
  {
    nixosConfigurations = {
      gnome-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./gnome-desktop.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./users/fdm/home.nix;
          }
        ];
      };
      xmonad-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./xmonad-desktop.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./users/fdm/home.nix;
          }
        ];
      };
      vps = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./vps.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.vps-admin = ./users/vps-admin/home.nix;
          }
        ];
      };
    };
  };
}

