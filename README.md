[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

# nixos
This is my personal NixOS configuration.

## Repository Structure
### /machines/
System configuration for my various NixOS hosts. Each machine referencecs a home-manager profile for module management.
### /profiles/
Individual home-manager module configurations.
### /modules/
Home-manager module configurations shared by all profiles.

## Installation
1. Install NixOS using a live installation medium.
2. `nix-shell -p git`
3. `git clone https://github.com/maurerf/nixos`
4. `sudo cp -r nixos/* /etc/nixos/*`
5. `sudo nixos-rebuild switch --flake <Identifier>`.

## Flakes
| Identifier | Description                                                                                                                      | Profile |
|------------|----------------------------------------------------------------------------------------------------------------------------------|---------|
| minimal    | Bare-bones system configuration forming the base for all my other NixOS flakes. Also works as a standalone for debugging purposes.  | minimal |
| laptop     | My daily driver: Minimalist GNOME desktop geared towards productivity and stability.                                             | pc      |
| pc         | Like laptop, but with gaming and VM support.                                                                                     | pc      |
| vps        | Used to host my own email server.                                                                                                | vps     |
