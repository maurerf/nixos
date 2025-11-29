[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

# nixos
This is my personal NixOS and Nix-Darwin configuration.

## Repository Structure
### /machines/
System configuration for my various hosts (both NixOS and Darwin). Each machine references a home-manager profile for module management.
### /hardware/
Hardware specifics for computers on which systems defined in /machines/ may be hosted.
### /profiles/
Home-manager configurations organized by platform:
- `/darwin/` - macOS-specific home-manager configuration
- `/vps/` - VPS-specific home-manager configuration  
- `/shared/` - Shared base configuration used across platforms
### /modules/
Home-manager module configurations shared by all profiles (git, zsh, etc.).

## Installation

### NixOS
```bash
sudo nixos-rebuild switch --flake github:maurerf/nixos#vps
```

### Darwin (macOS)
```bash
darwin-rebuild switch --flake github:maurerf/nixos#m2-macbook-air
```


## Configurations
| Configuration               | Description                                                                                                                          | Type      |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------|-----------|
| `vps`                       | NixOS configuration for VPS hosting email server with mailserver module integration.                                                | NixOS     |
| `m2-macbook-air`            | Darwin configuration for M2 MacBook Air with development tools and desktop applications.                                            | Darwin    |
