{
  description = "NixOS Flake: Desktop PC, VPS, laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    #nixpkgs2305.url = "github:NixOS/nixpkgs/nixos-23.05";
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs-23_05.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, simple-nixos-mailserver }:
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
          inputs.simple-nixos-mailserver.nixosModules.mailserver
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./users/fdm-vps/home.nix;
          }
        ];
      };
    };
  };
}

