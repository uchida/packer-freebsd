#!/bin/sh
set -ex
case "$PACKER_BUILDER_TYPE" in
  virtualbox-*)
    pkg install -y virtualbox-ose-additions
    sysrc vboxnet_enable="YES"
    sysrc vboxguest_enable="YES"
    sysrc vboxservice_enable="YES"
    ;;
  vmware-*)
    pkg install -y open-vm-tools-nox11
    sysrc ifconfig_vxn0="dhcp"
    sysrc vmware_guest_vmblock_enable="YES"
    sysrc vmware_guest_vmhgfs_enable="YES"
    sysrc vmware_guest_vmmemctl_enable="YES"
    sysrc vmware_guest_vmxnet_enable="YES"
    sysrc vmware_guestd_enable="YES"
    ;;
esac
