#!/bin/bash

DEVICE=/dev/kiwixusb
MOUNTPOINT=/media/usb2

function killserve {
        killall kiwix-serve
}

function startserve {
        /root/kiwix/server/kiwix-serve --library --port=4201 --daemon /media/usb2/library.xml
}

function attach {
        mount -oumask=000 $1 /media/usb2/
}

function detach {
        umount -fl $MOUNTPOINT
}

killserve
sleep 2
detach
sleep 3
if [ `ls -l /dev/kiwixusb |grep -v sda |grep -v sdb |wc -l` = "1" ] ; then
        attach $DEVICE
        sleep 3
        startserve
fi
