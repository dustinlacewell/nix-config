{ config, pkgs, ... }:
# only dell latitude E6430 specific settings
{
imports = [ ../../modules ];

system.stateVersion = "18.03";
networking.hostName = "latitudeE6430";

# my modules
modules.workstation.enable = true;
modules.intelgfx.enable = true;
modules.exwm.enable = true;
modules.dotfiles.enable = true;
modules.libvirtd.enable = true;

# machine specific
nix.buildCores = 0;
nix.maxJobs = 4;
boot.kernelModules = [ "microcode" "coretemp" ];
boot.kernelParams = [ "i915.enable_fbc=1" ];
boot.initrd.kernelModules = [ "i915" ];

# boost laptop power savings
powerManagement.enable = true;
services.tlp.enable = true;

# touchpad
services.xserver.libinput.enable = true;
services.xserver.libinput.accelSpeed = "0.9";
}
