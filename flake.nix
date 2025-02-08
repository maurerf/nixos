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
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, simple-nixos-mailserver, nix-darwin }:
  let
    system = "x86_64-linux";
  in 
  {
    nixosConfigurations = {
      pc = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/pc.nix
          ./hardware/pc.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/pc/home.nix;
          }
        ];
      };
      thinkpad-l450 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/laptop.nix
          ./hardware/thinkpad-l450.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/pc/home.nix; #laptops use the same host profile as pc
          }
        ];
      };
      thinkpad-t440s = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/laptop.nix
          ./hardware/thinkpad-t440s.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/pc/home.nix; #laptops use the same host profile as pc
          }
        ];
      };
      laptop-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/laptop.nix
          ./hardware/vm.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/pc/home.nix; #laptops use the same host profile as pc
          }
        ];
      };
      minimal = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/minimal.nix
          ./hardware-configuration.nix # NOTE: as this minimal flake is hardware-agnostic, you cannot directly access it from remote
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/minimal/home.nix;
          }
        ];
      };
      vps = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./machines/vps.nix
          ./hardware/vultr-vps.nix
          inputs.simple-nixos-mailserver.nixosModules.mailserver
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/vps/home.nix;
          }
        ];
      };
    };

    darwinConfigurations = {
      "m2-macbook-air" = nix-darwin.lib.darwinSystem {
        modules = [
          ./machines/m2-macbook-air.nix
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.fdm = ./profiles/darwin/home.nix;
          }
        ];
      };
    };
  };
}
