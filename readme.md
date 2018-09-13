## What
This repo contains all of my Linux configuration files for everything I do on a computer.
Using this setup, I am able to bootstrap my complete, custom NixOS installations in one-command.
This includes zfs-on-root with auto snapshotting, custom disk array and pool setup,
my operating system services and settings, all of my favorite applications-- _the works!_

## Why
I like to build robust and reproducible, automated systems.
By reducing state we can increase productivity and developer happiness. :)

Let's just call it, "personal computer hygeine."

## How it works
1. [Themelios](https://github.com/a-schaefers/themelios) is built into a NixOS
[livedisk](https://github.com/a-schaefers/nix-config/blob/master/iso/myrescueiso.nix)
and bootstraps machine-specific installations, using the configuration.sh and default.nix files
within the [hosts/ directory](https://github.com/a-schaefers/nix-config/tree/master/hosts).

2. [NixOS](https://nixos.org/) with
[lib/recimport.nix](https://github.com/a-schaefers/nix-config/blob/master/lib/recimport.nix)
auto-imports _everything_ in the
[modules/ directory](https://github.com/a-schaefers/nix-config/tree/master/modules). The
corresponding hosts/machine-name/default.nix file determines which modules should
actually be enabled or not.

3. I use Emacs for nearly everything I do, it is the central hub of my workflow. The following are
just a few of my favorite Emacs packages that I use daily:
  - exwm (window manager)
  - gnus (email)
  - erc (irc)
  - emms (media player)
  - pdf-tools (pdf viewer)
  - image-mode (image viewer)
  - eww (browser)
  - org-mode (todo lists, planning and time-management)
  - shell and ansi-term (terminals)
  - [And much more...](https://github.com/a-schaefers/nix-config/tree/master/dotfiles/.emacs.d/lisp.d)
  I have made an exception for Emacs, instead of using the nix built-in package manager, in my
[dotfiles/.emacs.d/init.el](https://github.com/a-schaefers/nix-config/blob/master/dotfiles/.emacs.d/init.el)
I use [straight.el](https://github.com/raxod502/straight.el), which
allows for both for highly flexible configurations and reproducible Emacs
package management with [use-package](https://github.com/jwiegley/use-package) integration.

## laptop:
```bash
[root@nixos:~] themelios latitudeE6430 a-schaefers/nix-config
```

## workstation:
```bash
[root@nixos:~] themelios hpZ620 a-schaefers/nix-config
```

## Thanks
In addition to all the previously mentioned projects, everyone in #nixos and #emacs on freenode,
and to [ldlework](https://github.com/dustinlacewell/dotfiles)
who has an excellent setup which inspired many things about my own.

# May the source be with you. |—O—|
