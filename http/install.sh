#!/bin/sh
set -ex

for d in ada0 da0 vtbd0; do
  if [ -e "/dev/$d" ]; then
    export ZFSBOOT_DISKS=$d
    break
  fi
done

export BSDINSTALL_CHROOT=/mnt
export DISTRIBUTIONS="kernel.txz base.txz lib32.txz"
export nonInteractive=YES

bsdinstall zfsboot
bsdinstall mount
bsdinstall checksum
bsdinstall distextract
bsdinstall config
bsdinstall entropy

echo "packer" | pw -V $BSDINSTALL_CHROOT/etc usermod root -h 0
echo "PermitRootLogin yes" >> $BSDINSTALL_CHROOT/etc/ssh/sshd_config

chroot $BSDINSTALL_CHROOT sysrc sshd_enable="YES"
interface="`ifconfig -l | cut -d' ' -f1`"
chroot $BSDINSTALL_CHROOT sysrc ifconfig_$interface="dhcp"

shutdown -r now
