#!/usr/bin/env bash

# Usage : nix-on-zroot -g <git-url> -h <host.nix>

# Copyright 2018 sch@efers.org
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

__usage_check() {
    usage ()
    {
        echo "Usage : nix-on-zroot -g <git-url> -h <host.nix>"
        exit
    }

    if [ "$#" -ne 13 ]
    then
        usage
    fi

    while [ "$1" != "" ]; do
        case $1 in
            -g )           shift
                           NIXCFG_REPO=$1
                           ;;
            -h )           shift
                           NIXCFG_HOST=$1
                           ;;
        esac
        shift
    done

    # extra validation
    if [ "${NIXCFG_REPO}" = "" ]
    then
        usage
    fi
    if [ "${NIXCFG_HOST}" = "" ]
    then
        usage
    fi
}

__switch_if_needed() {
    if [[ ${NEEDS_SWITCH} == "true" ]]
    then
        nixos-rebuild switch
        NEEDS_SWITCH="false"
    fi
}

__uefi_or_legacy() {
    # TODO add uefi support.
    if [ -d "/sys/firmware/efi/efivars" ]; then
        exit ; echo "Only legacy bios is supported with this script for now."
    fi
}

__initial_warning() {
    echo "WARNING: The following script intends to replace all of your disk(s) \
contents with a fresh zfs-on-root NixOS installation."
    echo ""
    read -p "Continue? (Y or N) " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Aborted." ; exit
    fi
}

__bootstrap_zfs() {
    __install_zfs() {
            sed -i '/imports/a \
boot.supportedFilesystems = [ \"zfs\" ];' \
        /etc/nixos/configuration.nix
    NEEDS_SWITCH="true"
    }
    which zfs > /dev/null 2>&1 || __install_zfs
}

__bootstrap_git() {
    __install_git() {
     sed -i '/imports/a \
 environment.systemPackages = with pkgs; [ git ];' \
        /etc/nixos/configuration.nix
    NEEDS_SWITCH="true"
    }
    which git > /dev/null 2>&1 || __install_git
}

__disk_prep() {
    if [[ ${REMOVE_REMNANTS} == "true" ]]
    then
        for DISK_ID in ${POOL_DISKS}
        do
            sgdisk --clear ${DISK_ID}
            wipefs --all ${DISK_ID}
        done
    fi
}

__zpool_create() {
    zpool create -f \
          -o ashift=12 \
          -O compression=lz4 \
          -O atime=${ATIME:?"Please define atime."} \
          -O relatime=on \
          -O normalization=formD \
          -O xattr=sa \
          -m none \
          -R /mnt \
          ${POOL_NAME:?"Please define pool name."} \
          ${POOL_TYPE} \
          ${POOL_DISKS:?"Please define pool disks."}

    IFS=$'\n'
    for DISK_ID in ${POOL_DISKS}
    do
        sgdisk -a1 -n2:48:2047 -t2:EF02 -c2:"BIOS boot partition" ${DISK_ID}
        partx -u ${DISK_ID}
    done
}

__datasets_create() {
    # / (root) datasets
    zfs create -o mountpoint=none -o canmount=off -o sync=always ${POOL_NAME}/ROOT
    zfs create -o mountpoint=legacy -o canmount=on ${POOL_NAME}/ROOT/nixos
    zpool set bootfs=${POOL_NAME}/ROOT/nixos ${POOL_NAME}
    mount -t zfs ${POOL_NAME}/ROOT/nixos /mnt

    mkdir /mnt/{home,tmp}

    # /home datasets
    zfs create -o mountpoint=none -o canmount=off ${POOL_NAME}/HOME
    zfs create -o mountpoint=legacy -o canmount=on ${POOL_NAME}/HOME/home
    mount -t zfs ${POOL_NAME}/HOME/home /mnt/home

    # /tmp datasets
    zfs create -o mountpoint=none -o canmount=off ${POOL_NAME}/TMP
    zfs create -o mountpoint=legacy -o canmount=on -o sync=disabled ${POOL_NAME}/TMP/tmp
    mount -t zfs ${POOL_NAME}/TMP/tmp /mnt/tmp

    # zswap option
    if [[ ${USE_ZSWAP} == "true" ]]
    then
        zfs create \
            -o primarycache=metadata \
            -o secondarycache=metadata \
            -o compression=zle \
            -o sync=always \
            -o logbias=throughput \
            -o com.sun:auto-snapshot=false \
            ${POOL_NAME}/SWAP

        zfs create \
            -V ${ZSWAP_SIZE} \
            -b $(getconf PAGESIZE) \
            ${POOL_NAME}/SWAP/swap0

        mkswap -f /dev/zvol/${POOL_NAME}/SWAP/swap0
        swapon /dev/zvol/${POOL_NAME}/SWAP/swap0
    fi
}

__zfs_auto_snapshot() {
    if [[ ${SNAPSHOT_HOME} == "true" ]]
    then
        zfs set com.sun:auto-snapshot=true ${POOL_NAME}/HOME
    elif [[ ${SNAPSHOT_ROOT} == "true" ]]
    then
        zfs set com.sun:auto-snapshot=true ${POOL_NAME}/ROOT
    fi
}

__get_custom_nixcfg() {
    # TODO git preserve permissions and restore from https to git remotes
    git clone ${NIXCFG_REPO} /tmp/NIXCFG_REPO

    BOOTSTRAP_BLOCK=$(grep "#|" ${NIXCFG_DIR}${NIXCFG_HOST} | cut -d '|' -f 2)
    IFS=$'\n'
    for CFG_VAR in ${BOOTSTRAP_BLOCK}
    do
        export ${CFG_VAR}
    done

    # put the repo in its proper location now
    cp -rp /tmp/NIXCFG_REPO /mnt${NIXCFG_LOCATION}

    # translate configure options from true/false to zfs style "on/off"
    if [[ ${ATIME} == "true" ]]
    then
        ATIME="on"
    else
        ATIME="off"
    fi
}

__bootstrap_nixcfg() {
    nixos-generate-config --root /mnt

    if [[ ${POOL_HOSTID} == "random" ]]
    then
        POOL_HOSTID="$(head -c4 /dev/urandom | od -A none -t x4 | cut -d ' ' -f 2)"
    fi

    cat <<EOF > /mnt/etc/nixos/configuration.nix
{ ... }:
{ imports = [
/etc/nixos/hardware-configuration.nix
];
networking.hostId = "${POOL_HOSTID}";
}
EOF
    sed -i '/imports/a ${NIXCFG_LOCATION}hosts/${NIXCFG_HOST}' \
        /mnt/etc/nixos/configuration.nix

    # TODO
    # nixos-install
    # zpool export ${POOL_NAME}
    # ask user if would like to make any further changes before reboot
}

__thank_you() {
    cat <<EOF
NNNNNNNN        NNNNNNNNIIIIIIIIIIXXXXXXX       XXXXXXX
N:::::::N       N::::::NI::::::::IX:::::X       X:::::X
N::::::::N      N::::::NI::::::::IX:::::X       X:::::X
N:::::::::N     N::::::NII::::::IIX::::::X     X::::::X
N::::::::::N    N::::::N  I::::I  XXX:::::X   X:::::XXX
N:::::::::::N   N::::::N  I::::I     X:::::X X:::::X
N:::::::N::::N  N::::::N  I::::I      X:::::X:::::X
N::::::N N::::N N::::::N  I::::I       X:::::::::X
N::::::N  N::::N:::::::N  I::::I       X:::::::::X
N::::::N   N:::::::::::N  I::::I      X:::::X:::::X
N::::::N    N::::::::::N  I::::I     X:::::X X:::::X
N::::::N     N:::::::::N  I::::I  XXX:::::X   X:::::XXX
N::::::N      N::::::::NII::::::IIX::::::X     X::::::X
N::::::N       N:::::::NI::::::::IX:::::X       X:::::X
N::::::N        N::::::NI::::::::IX:::::X       X:::::X
NNNNNNNN         NNNNNNNIIIIIIIIIIXXXXXXX       XXXXXXX
EOF
}

# SCRIPT OUTLINE

__stage_1() {
    __usage_check          # check for proper script input from user
    __uefi_or_legacy       # check for legacy or uefi bios
    __initial_warning      # warn user of potential doom
}

__stage_2() {
    __bootstrap_zfs        # install zfs if needed to the livedisk
    __bootstrap_git        # install git if needed to the livedisk
    __switch_if_needed     # reconfigure nix livedisk if needed
    __get_custom_nixcfg    # download the host machine configuration
    __disk_prep            # use sgdisk and wipefs to cleanup old disks
    __zpool_create         # create the zpool, make gpt bios boot partition
    __datasets_create      # create a zfs dataset layout
    __zfs_auto_snapshot    # set com.sun:auto-snapshot properties
}

__stage_3() {
    __bootstrap_nixcfg     # bootstrap the users custom nix configurations
    __thank_you            # May you have a Happy Hacking. :)
}

#################
# Action !      #
#################

__stage_1
__stage_2
__stage_3
