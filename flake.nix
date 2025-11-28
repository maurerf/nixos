{
  description = "maurerf's personal NixOS and nix-darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, simple-nixos-mailserver, nix-darwin }:
  let
    nixosSystem = "x86_64-linux";
    darwinSystem = "aarch64-darwin";
  in 
  {
    nixosConfigurations = {
      vps = nixpkgs.lib.nixosSystem {
        system = nixosSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/vps.nix
          ./hardware/vultr-vps.nix
          simple-nixos-mailserver.nixosModules.mailserver
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/vps/home.nix;
          }
        ];
      };
    };

    darwinConfigurations = {
      "m2-macbook-air" = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        modules = [
          ./machines/m2-macbook-air.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = import ./profiles/darwin/home.nix;
          }
        ];
      };
    };
  };
}
