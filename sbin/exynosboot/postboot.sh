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

# chmod everything in res dir
MOUNT_RW;
$BB chmod -R 777 /res/*


IOSCHED_TUNING()
{
	for f in /sys/block/mmcblk*/queue;
	do
	  echo "zen" > "$f"/scheduler;
	  TUNABLES="$f"/iosched;
	  echo "0" > "$f"/nomerges;
	  echo "512" > "$f"/nr_requests;
	  echo "1024" > "$f"/read_ahead_kb;
	  
	  # zen tunng
	  echo "2" > "$TUNABLES"/fifo_batch;
	done;
}
IOSCHED_TUNING;

CPU_TUNING_STOCK()
{
	# A7 cluster to stock 500MHz min after boot and A15 cluster to 800MHz stock
	echo "500000" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq;
	echo "800000" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq;
}
CPU_TUNING_STOCK;

# Relax IPA thermal
$BB echo "70" > /sys/power/ipa/control_temp

# Disable lmk_fast_run
$BB echo "0" > /sys/module/lowmemorykiller/parameters/lmk_fast_run

# Start any init.d scripts that may be present in the rom or added by the user
MOUNT_RW;
$BB chmod -R 755 /system/etc/init.d/

$BB run-parts /system/etc/init.d

# Start uci
MOUNT_RW;
$BB sh /res/synapse uci
$BB ln -s /res/synapse/uci /system/xbin/uci

$BB echo "postboot.sh done\n" >> /sdcard/duki994.txt
