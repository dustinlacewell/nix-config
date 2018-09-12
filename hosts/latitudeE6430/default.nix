{ config, pkgs, ... }:
# only dell latitude E6430 specific settings
{
imports = [ ../../modules ];

networking.hostName = "latitudeE6430";

# my modules
modules.general.enable = true;
modules.desktop.enable = true;
modules.libvirtd.enable = true;

# hardware specific
nix.buildCores = 0;
nix.maxJobs = 4;
boot.kernelModules = [ "microcode" "coretemp" ];
boot.kernelParams = [ "i915.enable_fbc=1" ];
boot.initrd.kernelModules = [ "i915" ];

# boost laptop power savings
services.tlp.enable = true;

# touchpad
services.xserver.libinput.enable = true;
services.xserver.libinput.accelSpeed = "0.9";

# intel laptop video
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

hardware.opengl.extraPackages = with pkgs;
[ vaapiIntel libvdpau-va-gl vaapiVdpau ];
hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux;
[ vaapiIntel libvdpau-va-gl vaapiVdpau ];

environment.sessionVariables = {
LIBVA_DRIVER_NAME = "i965";
VDPAU_DRIVER = "va_gl";
};

programs.light.enable = true;

# This value determines the NixOS release with which your system is to be
# compatible, in order to avoid breaking some software such as database
# servers. You should change this only after NixOS release notes say you
# should.
system.stateVersion = "18.03"; # Did you read the comment?
}
