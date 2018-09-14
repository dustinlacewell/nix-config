{ config, pkgs, lib, ... }:
with lib;
{
options.modules.amdgpu.enable = mkEnableOption "Amdgpu Profile";
config = mkIf config.modules.amdgpu.enable {

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
[ libvdpau-va-gl vaapiVdpau ];
hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux;
[ libvdpau-va-gl vaapiVdpau ];
};
}