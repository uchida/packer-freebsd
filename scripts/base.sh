#!/bin/sh
set -ex

sed -e 's/\[ ! -t 0 \]/false/' /usr/sbin/freebsd-update > /tmp/freebsd-update
chmod +x /tmp/freebsd-update
env PAGER=cat /tmp/freebsd-update fetch
env PAGER=cat /tmp/freebsd-update install
echo WITH_PKGNG=yes >> /etc/make.conf
env ASSUME_ALWAYS_YES=YES pkg bootstrap
pkg update
sysrc 'rpcbind_enable="YES"'
sysrc 'nfs_server_enable="YES"'
sysrc 'mountd_flags="-r"'
