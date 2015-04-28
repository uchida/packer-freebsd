#!/bin/sh

mkdir -p /tmp/bsdinstall
cp /usr/libexec/bsdinstall/* /tmp/bsdinstall
mdmfs -s 1m md3 /usr/libexec/bsdinstall
cp /tmp/bsdinstall/* /usr/libexec/bsdinstall
rm -rf /tmp/bsdinstall

patch -p4 -d /usr/libexec/bsdinstall <<"EOF"
--- a/usr.sbin/bsdinstall/scripts/zfsboot
+++ b/usr.sbin/bsdinstall/scripts/zfsboot
@@ -65,9 +65,9 @@ f_include $BSDCFG_SHARE/variable.subr
 : ${ZFSBOOT_VDEV_TYPE:=stripe}
 
 #
-# Should we use gnop(8) to configure a transparent mapping to 4K sectors?
+# Should we use sysctl(8) vfs.zfs.min_auto_ashift=12 to force 4K sectors?
 #
-: ${ZFSBOOT_GNOP_4K_FORCE_ALIGN:=1}
+: ${ZFSBOOT_FORCE_4K_SECTORS:=1}
 
 #
 # Should we use geli(8) to encrypt the drives?
@@ -185,8 +185,6 @@ ECHO_APPEND='echo "%s" >> "%s"'
 GELI_ATTACH='geli attach -j - -k "%s" "%s"'
 GELI_DETACH_F='geli detach -f "%s"'
 GELI_PASSWORD_INIT='geli init -b -B "%s" -e %s -J - -K "%s" -l 256 -s 4096 "%s"'
-GNOP_CREATE='gnop create -S 4096 "%s"'
-GNOP_DESTROY='gnop destroy "%s"'
 GPART_ADD='gpart add -t %s "%s"'
 GPART_ADD_INDEX='gpart add -i %s -t %s "%s"'
 GPART_ADD_INDEX_WITH_SIZE='gpart add -i %s -t %s -s %s "%s"'
@@ -205,6 +203,7 @@ PRINTF_CONF="printf '%s=\"%%s\"\\\n' %s >> \"%s\""
 PRINTF_FSTAB='printf "$FSTAB_FMT" "%s" "%s" "%s" "%s" "%s" "%s" >> "%s"'
 SHELL_TRUNCATE=':> "%s"'
 SWAP_GMIRROR_LABEL='gmirror label swap %s'
+SYSCTL_ZFS_MIN_ASHIFT_12='sysctl vfs.zfs.min_auto_ashift=12'
 UMOUNT='umount "%s"'
 ZFS_CREATE_WITH_OPTIONS='zfs create %s "%s"'
 ZFS_SET='zfs set "%s" "%s"'
@@ -236,7 +235,7 @@ msg_encrypt_disks="Encrypt Disks?"
 msg_encrypt_disks_help="Use geli(8) to encrypt all data partitions"
 msg_error="Error"
 msg_force_4k_sectors="Force 4K Sectors?"
-msg_force_4k_sectors_help="Use gnop(8) to configure forced 4K sector alignment"
+msg_force_4k_sectors_help="Use sysctl(8) vfs.zfs.min_auto_ashift=12 to force 4K sectors"
 msg_freebsd_installer="FreeBSD Installer"
 msg_geli_password="Enter a strong passphrase, used to protect your encryption keys. You will be required to enter this passphrase each time the system is booted"
 msg_geli_setup="Initializing encryption on selected disks,\n this will take several seconds per disk"
@@ -315,7 +314,7 @@ dialog_menu_main()
 	local usegeli="$msg_no"
 	local swapgeli="$msg_no"
 	local swapmirror="$msg_no"
-	[ "$ZFSBOOT_GNOP_4K_FORCE_ALIGN" ] && force4k="$msg_yes"
+	[ "$ZFSBOOT_FORCE_4K_SECTORS" ] && force4k="$msg_yes"
 	[ "$ZFSBOOT_GELI_ENCRYPTION" ] && usegeli="$msg_yes"
 	[ "$ZFSBOOT_SWAP_ENCRYPTION" ] && swapgeli="$msg_yes"
 	[ "$ZFSBOOT_SWAP_MIRROR" ] && swapmirror="$msg_yes"
@@ -1062,36 +1061,22 @@ zfs_create_boot()
 	# Prepare the disks and build pool device list(s)
 	#
 	f_dprintf "$funcname: Preparing disk partitions for ZFS pool..."
-	[ "$ZFSBOOT_GNOP_4K_FORCE_ALIGN" ] &&
-		f_dprintf "$funcname: With 4k alignment using gnop(8)..."
+
+	# Force 4K sectors using vfs.zfs.min_auto_ashift=12
+	if [ "$ZFSBOOT_FORCE_4K_SECTORS" ]; then
+		f_dprintf "$funcname: With 4K sectors..."
+		f_eval_catch $funcname sysctl "$SYSCTL_ZFS_MIN_ASHIFT_12" \
+		    || return $FAILURE
+	fi
 	local n=0
 	for disk in $disks; do
 		zfs_create_diskpart $disk $n || return $FAILURE
 		# Now $bootpart, $targetpart, and $swappart are set (suffix
 		# for $disk)
-		
-		# Forced 4k alignment support using Geom NOP (see gnop(8))
-		if [ "$ZFSBOOT_GNOP_4K_FORCE_ALIGN" ]; then
-			if [ "$ZFSBOOT_BOOT_POOL" ]; then
-				boot_vdevs="$boot_vdevs $disk$bootpart.nop"
-				f_eval_catch $funcname gnop "$GNOP_CREATE" \
-				             $disk$bootpart || return $FAILURE
-			fi
-			# Don't gnop encrypted partition
-			if [ "$ZFSBOOT_GELI_ENCRYPTION" ]; then
-				zroot_vdevs="$zroot_vdevs $disk$targetpart.eli"
-			else
-				zroot_vdevs="$zroot_vdevs $disk$targetpart.nop"
-				f_eval_catch $funcname gnop "$GNOP_CREATE" \
-					     $disk$targetpart ||
-				             return $FAILURE
-			fi
-		else
-			if [ "$ZFSBOOT_BOOT_POOL" ]; then
-				boot_vdevs="$boot_vdevs $disk$bootpart"
-			fi
-			zroot_vdevs="$zroot_vdevs $disk$targetpart"
+		if [ "$ZFSBOOT_BOOT_POOL" ]; then
+			boot_vdevs="$boot_vdevs $disk$bootpart"
 		fi
+		zroot_vdevs="$zroot_vdevs $disk$targetpart"
 
 		n=$(( $n + 1 ))
 	done # disks
@@ -1266,18 +1251,6 @@ zfs_create_boot()
 		             "$bootpool_name" || return $FAILURE
 	fi
 
-	# Destroy the gnop devices (if enabled)
-	for disk in ${ZFSBOOT_GNOP_4K_FORCE_ALIGN:+$disks}; do
-		if [ "$ZFSBOOT_BOOT_POOL" ]; then
-			f_eval_catch -d $funcname gnop "$GNOP_DESTROY" \
-			                $disk$bootpart.nop
-		fi
-		if [ ! "$ZFSBOOT_GELI_ENCRYPTION" ]; then
-			f_eval_catch -d $funcname gnop "$GNOP_DESTROY" \
-			                $disk$targetpart.nop
-		fi
-	done
-
 	# MBR boot loader touch-up
 	if [ "$ZFSBOOT_PARTITION_SCHEME" = "MBR" ]; then
 		f_dprintf "$funcname: Updating MBR boot loader on disks..."
@@ -1544,10 +1517,10 @@ while :; do
 		;;
 	?" $msg_force_4k_sectors")
 		# Toggle the variable referenced both by the menu and later
-		if [ "$ZFSBOOT_GNOP_4K_FORCE_ALIGN" ]; then
-			ZFSBOOT_GNOP_4K_FORCE_ALIGN=
+		if [ "$ZFSBOOT_FORCE_4K_SECTORS" ]; then
+			ZFSBOOT_FORCE_4K_SECTORS=
 		else
-			ZFSBOOT_GNOP_4K_FORCE_ALIGN=1
+			ZFSBOOT_FORCE_4K_SECTORS=1
 		fi
 		;;
 	?" $msg_encrypt_disks")
@@ -1555,7 +1528,7 @@ while :; do
 		if [ "$ZFSBOOT_GELI_ENCRYPTION" ]; then
 			ZFSBOOT_GELI_ENCRYPTION=
 		else
-			ZFSBOOT_GNOP_4K_FORCE_ALIGN=1
+			ZFSBOOT_FORCE_4K_SECTORS=1
 			ZFSBOOT_GELI_ENCRYPTION=1
 		fi
 		;;
EOF
