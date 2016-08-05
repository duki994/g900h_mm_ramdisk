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



# Relax IPA thermal
$BB chmod 777 /sys/power/ipa/control_temp

$BB echo "70" > /sys/power/ipa/control_temp



# Disable lmk_fast_run
$BB echo "0" > /sys/module/lowmemorykiller/parameters/lmk_fast_run



# Tune entropy
$BB echo "512" > /proc/sys/kernel/random/read_wakeup_threshold

$BB echo "256" > /proc/sys/kernel/random/write_wakeup_threshold



# Properly calibrate sound-control HP equalizer freqs. Thanks to @AndreiLux <https://www.github.com/AndreiLux>

$BB echo "0x0FF3 0x041E 0x0034 0x1FC8 0xF035 0x040D 0x00D2 0x1F6B 0xF084 0x0409 0x020B 0x1EB8 0xF104 0x0409 0x0406 0x0E08 0x0782 0x2ED8" > /sys/class/misc/arizona_control/eq_A_freqs

$BB echo "0x0C47 0x03F5 0x0EE4 0x1D04 0xF1F7 0x040B 0x07C8 0x187D 0xF3B9 0x040A 0x0EBE 0x0C9E 0xF6C3 0x040A 0x1AC7 0xFBB6 0x0400 0x2ED8" > /sys/class/misc/arizona_control/eq_B_freqs

# Workaround headset out call no sound bug
$BB echo "1" > /sys/class/misc/arizona_control/switch_eq_hp

# Start any init.d scripts that may be present in the rom or added by the user
MOUNT_RW;
$BB chmod -R 755 /system/etc/init.d/

$BB run-parts /system/etc/init.d



# Start uci
MOUNT_RW;
$BB sh /res/synapse uci
$BB ln -s /res/synapse/uci /system/xbin/uci

$BB echo "postboot.sh done\n" >> /sdcard/duki994.txt
