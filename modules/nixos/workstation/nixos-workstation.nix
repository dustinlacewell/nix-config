{ config, pkgs, lib, ... }:

with lib;
  let
    myEmacs = (pkgs.emacs.override {withGTK3=false; withGTK2=false; withX=true;});
  in
{
  options.mine.workstation.enable = mkEnableOption "Workstation Profile";

  config = mkIf config.mine.workstation.enable {

    # misc services I don't really use

    # services.samba.enable = true;
    # services.locate.enable = true;
    # services.printing.enable = true;
    # services.avahi.enable = true;
    # services.avahi.nssmdns = true;

    services.acpid.enable = true;
    services.smartd.enable = true;

    # pulseaudio
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # mesa
    hardware.opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };

    # Xorg, Slim, Emacs
    services.xserver = {
      enable = true;
      layout = "us";
      useGlamor = true;
      displayManager.slim.enable = true;
      displayManager.slim.autoLogin = false;
      displayManager.slim.defaultUser = "adam";
      displayManager.sessionCommands = ''
        ${pkgs.xlibs.xsetroot}/bin/xsetroot -cursor_name left_ptr
        ${pkgs.xlibs.xset}/bin/xset r rate 250 50
        ${pkgs.xlibs.xmodmap}/bin/xmodmap ~/.Xmodmap
        ${pkgs.numlockx}/bin/numlockx
        ${pkgs.dunst}/bin/dunst &
      '';
      desktopManager = {
        xterm.enable = false;
        default = "emacs";
        session = [ {
          manage = "desktop";
          name = "emacs";
          start = ''
            ${myEmacs}/bin/emacs &
            waitPID=$!
          '';}];};};

    environment.sessionVariables = {
      EDITOR = "emacsclient";
      VISUAL = "emacsclient";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    # some basic xft fonts
    fonts.fonts = with pkgs; [
      dejavu_fonts
      source-code-pro ];

    environment.systemPackages = with pkgs; [
      # Custom Emacs and some Emacs deps used by my config
      myEmacs
      shellcheck
      poppler_utils poppler_gi libpng12 zlib
      (python36.withPackages(ps: with ps; [ certifi ]))
      gnutls gnupg gnupg1compat

      # desktop support applications
      glxinfo
      wmctrl
      scrot
      xorg.xmodmap xorg.xev xorg.xrdb xorg.xset xorg.xsetroot
      numlockx
      xclip xsel
      libnotify dunst

      # desktop apps
      pandoc
      firefox qbittorrent mpv pavucontrol
      gimp kdenlive darktable krita inkscape

      # security
      openvpn
    ];

    programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
    };
}
