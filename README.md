[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

# nixos
This is my personal NixOS configuration.

## Repository Structure
### /machines/
System configuration for my various NixOS hosts. Each machine referencecs a home-manager profile for module management.
### /hardware/
Hardware specifics for computers on which systems defined in /machines/ may be hosted.
### /profiles/
Individual home-manager module configurations.
### /modules/
Home-manager module configurations shared by all profiles.

## Installation
`sudo nixos-rebuild switch --flake github:maurerf/nixos#<Flake>`


## Flakes
| Flake                       | Description                                                                                                                          | Machine   |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------|-----------|
| `minimal`                   | Bare-bones system configuration forming the base for all my other NixOS flakes. Also works as a standalone for debugging purposes.   | `minimal` |
| `thinkpad-t440s`            | My daily driver: Minimalist GNOME desktop geared towards productivity and stability.                                                 | `laptop`  |
| `thinkpad-l450`             | Backup for T440s.                                                                                                                    | `laptop`  |
| `pc`                        | Like laptop systems, but with gaming and VM support.                                                                                 | `pc`      |
| `vps`                       | Used to host my own email server.                                                                                                    | `vps`     |
