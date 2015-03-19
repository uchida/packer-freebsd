#!/bin/sh
set -ex
zfs create -o compression=off -o sync=standard -o mountpoint=/var/tmp zroot/empty
dd if=/dev/zero of=/var/tmp/EMPTY bs=1M || :
rm /var/tmp/EMPTY
sync
zfs destroy zroot/empty
