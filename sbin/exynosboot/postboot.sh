#!/sbin/busybox sh
# duki994 postboot script

BB=/sbin/busybox


MOUNT_RW() 
{

	if [ "$($BB mount | $BB grep rootfs | $BB cut -c 26-27 | $BB grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /;
	fi;

	if [ "$($BB mount | $BB grep system | $BB grep -c ro)" -eq "1" ]; then
		$BB mount -o remount,rw /system;
	fi;

}
MOUNT_RW;

PERMISSION_FIX()
{
	$BB chown -R root:root /tmp;
	$BB chown -R root:root /res;
	$BB chown -R root:root /sbin;
	$BB chown -R root:root /lib;
	$BB chmod -R 777 /tmp/; # for annoying tmp-mksh errors
	$BB chmod -R 775 /res/;	# for Synapse
	$BB chmod -R 06755 /sbin/exynosboot/; # for my scripts
	$BB chmod 06755 /sbin/busybox;
	$BB chmod 06755 /system/xbin/busybox;
}
PERMISSION_FIX;

SAMSUNG_FIX()
{
	# Disable Knox
	$BB pm disable com.sec.knox.seandroid;
	$BB setenforce 0;
	# setprop for WiFi not working fix
	$BB setprop ro.securestorage.support false;
}
SAMSUNG_FIX;

# create init.d folder
if [ ! -d /system/etc/init.d ]; then
	mkdir -p /system/etc/init.d/
	$BB chmod -R 755 /system/etc/init.d/;
fi;

#chmod everything in res dir
MOUNT_RW;
$BB chmod -R 777 /res/*

#### UKSM tuning #####
# 1000 ms scanning
$BB echo "1000" > /sys/kernel/mm/uksm/sleep_millisecs
# medium cpu gov
$BB echo "medium" > /sys/kernel/mm/uksm/cpu_governor
########################


### Set I/O zen ###
$BB echo "zen" > /sys/block/mmcblk0/queue/scheduler
$BB echo "1024" > /sys/block/mmcblk0/bdi/read_ahead_kb
$BB echo "2" >  /sys/block/mmcblk0/queue/nomerges

# Start any init.d scripts that may be present in the rom or added by the user
MOUNT_RW;
$BB chmod -R 755 /system/etc/init.d/

# Start uci
MOUNT_RW;
$BB sh /res/synapse uci
$BB ln -s /res/synapse/uci /system/xbin/uci
