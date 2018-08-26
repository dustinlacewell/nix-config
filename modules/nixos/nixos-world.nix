{ config, pkgs, ... }:
 # packages for all hosts
 {
   imports = [];

   environment.systemPackages = with pkgs; [
     wget
     curl
     inetutils
     nix-prefetch-scripts
     gptfdisk
     pmutils
     acpi
     acpid
     psmisc
     which
     file
     binutils
     bc
     utillinuxCurses
     exfat
     dosfstools
     patchutils
     moreutils
     unzip
     zip
     pciutils
     lshw
     usbutils
     lsof
     lm_sensors
     htop
     iotop
     powertop
     ltrace
     strace
     linuxPackages.perf
     smartmontools
   ];

 }
