{ config, pkgs, ... }:
# only dell latitude E6430 specific settings
{
imports = [ ../../modules ];

networking.hostName = "latitudeE6430";

# hardware specific
boot.kernelModules = [ "microcode" "coretemp" ];
boot.kernelParams = [ "i915.enable_fbc=1" ];
boot.initrd.kernelModules = [ "i915" ];

# my modules
modules.general.enable = true;
modules.desktop.enable = true;
modules.libvirtd.enable = true;

# boost laptop power savings
services.tlp.enable = true;

# touchpad
services.xserver.libinput.enable = true;
services.xserver.libinput.accelSpeed = "0.9";

# video
services.xserver.videoDrivers = [ "modesetting" ];
services.xserver.deviceSection = ''
Option "DRI" "3"
Option "TearFree" "true"
Option "AccelMethod" "glamor"
'';

services.compton = {
enable = true;
backend = "glx";
};

programs.light.enable = true;

# This value determines the NixOS release with which your system is to be
# compatible, in order to avoid breaking some software such as database
# servers. You should change this only after NixOS release notes say you
# should.
system.stateVersion = "18.03"; # Did you read the comment?
}
