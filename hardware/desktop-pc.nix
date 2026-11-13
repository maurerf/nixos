# Hand-written before install so CI can evaluate the host. Mounts by label
# (and the Windows ESP by PARTUUID), following the dual-boot layout decision:
# https://github.com/maurerf/nixos/issues/30
# Kernel modules match `nixos-generate-config` on the machine (2026-11-11):
# https://github.com/maurerf/nixos/issues/45
{ config, lib, modulesPath, ... }:

let
  btrfsSubvolume = subvol: {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=${subvol}" "compress=zstd" "noatime" ];
  };
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = btrfsSubvolume "@";
  fileSystems."/home" = btrfsSubvolume "@home";
  fileSystems."/nix" = btrfsSubvolume "@nix";

  # XBOOTLDR: kernels and initrds.
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # The existing Windows ESP: systemd-boot and loader.conf only.
  fileSystems."/efi" = {
    device = "/dev/disk/by-partuuid/66b88416-5d45-4cf6-8cf4-3c9a4523fc79";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # zram only (set in the machine); no swap partition and no hibernation.
  swapDevices = [ ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
