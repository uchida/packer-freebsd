#!/bin/sh
set -ex
rm -rf /var/db/freebsd-update/files
mkdir /var/db/freebsd-update/files
rm -f /var/db/freebsd-update/*-rollback
rm -rf /var/db/freebsd-update/install.*
rm -rf /boot/kernel.old
rm -f /*.core
rm -rf /tmp/*
