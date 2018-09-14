{ config, pkgs, lib, ... }:
with lib;
{
imports = [  ];

options.modules.libvirtd.enable = mkEnableOption "Libvirtd Profile";
config = mkIf config.modules.libvirtd.enable {

services.dnsmasq.enable = true;
virtualisation.libvirtd.enable = true;
environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";

environment.systemPackages = with pkgs; [
virtmanager
pkgs.gnome3.dconf # https://github.com/NixOS/nixpkgs/issues/42433
];

virtualisation.libvirtd.onShutdown = "shutdown";
};

}