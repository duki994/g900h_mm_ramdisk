#!/sbin/busybox sh

cat << CTAG
{
    name:"I/O",
    elements:[
	{ SPane:{
		title:"I/O scheduler choose",
        }},
	{ SOptionList:{
		title: "I/O sched",
		description:"Set desired I/O sched",
		default:deadline,
		action:"ioset scheduler",
		values:[
		     noop,
		     deadline,
		     cfq,
		     bfq,
		     fiops,
		     row,
		     zen,
		]
	}},
	{ SLiveLabel:{
                  title:"I/O sched",
                  description:"Current I/O sched.",
                  refresh:5000,
                  action:"cat /sys/block/mmcblk0/queue/scheduler"
        }},
	{ SSeekBar:{
		title:"Read ahead value",
		default:`cat /sys/block/mmcblk0/bdi/read_ahead_kb`,
		action:"ioset queue read_ahead_kb",
		unit:"kB", min:128, step:128, max:4096
	}},
    ]
}
CTAG
