{ config, pkgs, ... }:
{
nixpkgs.config = {
allowUnfree = true;
packageOverrides = pkgs: {
unstable = import <nixos-unstable> {};
};

nix.useSandbox = true;
};
}