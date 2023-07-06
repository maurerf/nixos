# nixos
This is my personal NixOS configuration.

### Installation for Desktop PC / Laptop
1. Install NixOS using a live installation medium.
2. `nix-shell -p git`
3. `git clone https://github.com/maurerf/nixos`
4. `sudo cp -r nixos/* /etc/nixos/*`
5. Edit `/etc/nixos/configuration.nix` by inserting the LUKS hash found in `/etc/nixos/hardware-configuration.nix`.
6. `sudo nixos-rebuild switch --flake .#desktop` or `sudo nixos-rebuild switch --flake .#laptop`

### Installation on VPS
1. Install NixOS using a live installation medium.
2. `nix-shell -p git`
3. `git clone https://github.com/maurerf/nixos`
4. `sudo cp -r nixos/* /etc/nixos/*`
6. `sudo nixos-rebuild switch --flake .#vps`
