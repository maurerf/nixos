{
  description = "maurerf's personal NixOS and nix-darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-26.05";
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
      "vps" = nixpkgs.lib.nixosSystem {
        system = nixosSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/vps.nix
          ./hardware/vultr-vps.nix
          simple-nixos-mailserver.nixosModules.mailserver
          home-manager.nixosModules.home-manager
          {
            system.configurationRevision = self.rev or null;
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/home-vps.nix;
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
            system.configurationRevision = self.rev or null;
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/home-darwin.nix;
          }
        ];
      };
    };
  };
}
