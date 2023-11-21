{
  description = "maurerf's personal NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, simple-nixos-mailserver }:
  let
    system = "x86_64-linux";
  in 
  {
    nixosConfigurations = {
      pc = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./pc.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./hosts/pc/home.nix;
          }
        ];
      };
      laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./laptop.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./hosts/pc/home.nix; #laptop uses the same host config as pc
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
            home-manager.users.fdm = ./hosts/vps/home.nix;
          }
        ];
      };
    };
  };
}

