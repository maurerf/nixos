# desktop-pc: Workstation with a Niri desktop and Steam, dual-booted beside
# Windows. Decisions: https://github.com/maurerf/nixos/issues/21
{ lib, pkgs, ... }:

{
  imports = [
    ../modules/nixos-base.nix
  ];

  networking.hostName = "desktop-pc";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";

  # systemd-boot on the Windows ESP (/efi), kernels on XBOOTLDR (/boot).
  # Windows Boot Manager is detected on the shared ESP. The menu defaults to
  # the newest generation (NixOS rewrites loader.conf on every switch).
  boot.loader.systemd-boot = {
    enable = true;
    xbootldrMountPoint = "/boot";
    configurationLimit = 10;
    editor = false;
  };
  boot.loader.efi = {
    efiSysMountPoint = "/efi";
    canTouchEfiVariables = true;
  };
  boot.loader.timeout = 5;
  zramSwap.enable = true;

  # SSH from the Mac is the rescue route, so its public key is declared here
  # and works from the first boot. Keyboard-interactive is off too, or PAM
  # would still accept the password.
  users.users.fdm.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeyUTBQK0BYz/cdQR8n6mzpGCrKPBTl+hcbqifCq8aK"
  ];
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
  users.users.fdm.extraGroups = [ "networkmanager" "gamemode" "input" "uinput" ];

  # Mac-style Super+C/V: the xremap user service (Home Manager profile) reads
  # keyboards and writes a virtual one, so fdm needs input and uinput. The
  # access trade-off is recorded in docs/decisions.md.
  hardware.uinput.enable = true;

  # NVIDIA open kernel modules on the default driver branch.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  # Niri wiki: stop the driver keeping a large free buffer pool for niri.
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text =
    builtins.toJSON {
      rules = [
        {
          pattern = { feature = "procname"; matches = "niri"; };
          profile = "Limit Free Buffer Pool On Wayland Compositors";
        }
      ];
      profiles = [
        {
          name = "Limit Free Buffer Pool On Wayland Compositors";
          settings = [ { key = "GLVidHeapReuseRatio"; value = 0; } ];
        }
      ];
    };

  # Session: Niri started by greetd + tuigreet. The module also brings the
  # swaylock PAM entry, polkit, portals and gnome-keyring; Nautilus is listed
  # below.
  programs.niri.enable = true;
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd niri-session";
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Audio and Bluetooth: module defaults, no WirePlumber overrides.
  hardware.bluetooth.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Gaming: plain Proton through Xwayland by default; gamescope per game only.
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  # Claude Code (glibc) runs through nix-ld; both coding tools sandbox with
  # bubblewrap, Claude Code also needs socat.
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite # Niri spawns it on demand for X11 apps (Steam)
    polkit_gnome # agent, started from niri.kdl
    nautilus
    libnotify # notify-send
    bubblewrap
    socat
    mangohud
  ];

  # `nixos-rebuild build-vm` / config.system.build.vm, run from NixOS-WSL with
  # nested KVM and virgl through WSLg. The VM uses its own disk image, so the
  # mounts above do not apply, and qemu-vm forces the modesetting driver, so
  # NVIDIA is off.
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      # Steam's bootstrap alone needs about 600 MB; the default 1 GiB is too small.
      diskSize = 10240;
      qemu.forceAccel = true;
      qemu.options = [
        "-vga none"
        "-device virtio-vga-gl,xres=1920,yres=1080"
        "-display gtk,gl=on"
      ];
    };
    # Throwaway login for the dry run only.
    users.users.fdm = {
      hashedPasswordFile = lib.mkForce null;
      initialPassword = "fdm";
    };
    # Windows captures Super, so the VM uses Alt as the Niri modifier. Windows
    # still takes Alt+Space and Alt+Escape; the run injects those through the
    # QEMU monitor (docs/deployment.md).
    home-manager.users.fdm.desktopPc.niriModKey = "Alt";
    # virgl through WSLg offers OpenGL 4.2; Ghostty needs 4.3 and renders
    # correctly with the version raised.
    environment.sessionVariables.MESA_GL_VERSION_OVERRIDE = "4.3";
  };
}
