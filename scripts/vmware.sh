#!/bin/sh
set -ex

mkdir /tmp/vmfusion
mkdir /tmp/vmfusion-archive

mdconfig -a -t vnode -f freebsd.iso -u 0
mount -t cd9660 /dev/md0 /tmp/vmfusion
tar xf /tmp/vmfusion/vmware-freebsd-tools.tar.gz -C /tmp/vmfusion-archive
umount /tmp/vmfusion
rm -rf /tmp/vmfusion

pkg install -y perl5 compat6x-`uname -m`
/tmp/vmfusion-archive/vmware-tools-distrib/vmware-install.pl --default
rm -rf /tmp/vmfusion-archive
rm freebsd.iso

echo 'ifconfig_vxn0="dhcp"' >> /etc/rc.conf
