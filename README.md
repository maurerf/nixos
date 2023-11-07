# nixos
This is my personal NixOS configuration.

### Installation
1. Install NixOS using a live installation medium.
2. `nix-shell -p git`
3. `git clone https://github.com/maurerf/nixos`
4. `sudo cp -r nixos/* /etc/nixos/*`
6. `sudo nixos-rebuild switch --flake .#pc` or `sudo nixos-rebuild switch --flake .#vps`
