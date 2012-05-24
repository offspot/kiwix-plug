#!/bin/bash

function yesno {
	if [[ $1 -eq 1 ]]
	then
		echo yes
	else
		echo no
	fi
}

# USB stick present
if [ ! `ls -l /dev/kiwixusb |grep -v sda |grep -v sdb |wc -l` = "0" ] ; then
usbpresent=1
else
usbpresent=0
fi

# USB mounted
if [ `mount |grep /media/usb2 | wc -l` = "1" ] ; then
usbmounted=1
else
usbmounted=0
fi

# USB has zim file
if [ `ls /media/usb2/*.zim` ] ; then
usbhaszim=1
else
usbhaszim=0
fi

# USB has library.xml
if [ -f /media/usb2/library.xml ] ; then
usbhaslibrary=1
else
usbhaslibrary=0
fi

# USB has index
if [ ! `find /media/usb2/ -name 'postlist.DB' |wc -l` = "0" ] ; then
usbhasindex=1
else
usbhasindex=0
fi

# Is kiwix-serve running?
if [ ! `ps aux |grep kiwix-serve | wc -l` = "0" ] ; then
kiwixserveisrunning=1
else
kiwixserveisrunning=0
fi

# Is kiwix-serve working?
if [ ! `wget http://localhost:4201 -qO- |grep "html" |wc -l` = "0" ] ; then
kiwixserveisworking=1
else
kiwixserveisworking=0
fi

# Does kiwix-serve has content?
if [ ! `wget http://localhost:4201 -qO- |grep "button" |wc -l` = "0" ] ; then
kiwixservehascontent=1
else
kiwixservehascontent=0
fi

# Is nginx running?
if [ ! `ps aux |grep nginx | wc -l` = "0" ] ; then
nginxisrunning=1
else
nginxisrunning=0
fi

echo -n "USB stick present? " ; yesno usbpresent
echo -n "USB mounted? " ; yesno usbmounted
echo -n "USB has a ZIM file? " ; yesno usbhaszim
echo -n "USB has a library file? " ; yesno usbhaslibrary
echo -n "USB has an index? " ; yesno usbhasindex
echo -n "nginx running? " ; yesno nginxisrunning
echo -n "kiwix-serve running? " ; yesno kiwixserveisrunning
echo -n "kiwix-serve working? " ; yesno kiwixserveisworking
echo -n "kiwix-serve has content? " ; yesno kiwixservehascontent

# assume a problem, blink BT led
if [ $kiwixservehascontent -eq 0 -o $kiwixserveisworking -eq 0 -o $kiwixserveisrunning -eq 0 -o $usbpresent -eq 0 -o $usbmounted -eq 0 -o $usbhaszim -eq 0 -o $nginxisrunning -eq 0 ] ; then
echo "Fault detected."
/root/leds --off 1
/root/leds -b 4
else
echo "All good."
/root/leds --on 1
/root/leds --off 4
/root/leds --noblink 4
fi

echo ""