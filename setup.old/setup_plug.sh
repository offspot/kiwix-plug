#!/bin/bash

DEFAULT_BINPATH=`pwd`/kiwix
DEFAULT_WWWROOT=/var/www/kiwix
DEFAULT_USBDEVICE=/dev/sdc1
DEFAULT_USBMOUNTPOINT=/media/usb2
DEFAULT_ZIMFILE=wikipedia_fr_all_07_2010_beta2.zim
DEFAULT_ZIMINDEX=wikipedia_fr_all_07_2010_beta2.index
DEFAULT_SSID=Wikipedia
DEFAULT_USEWIFIAP=1
DEFAULT_IFACE_MASQ=uap0
DEFAULT_USE_UAP=0

DL_KIWIX_TAR=http://download.kiwix.org/dev/kiwix-plug.tar.bz2

function check_quit {
    text="Are you ready to continue now? y/n     "
    if [ "$1" ]
    then
        text=$1
    fi
    echo -n $text
    read answer
    answer=echo $ans | tr '[:upper:]' '[:lower:]'
    if [ "$answer" != "y" ]
    then
        exit
    fi
}

echo "Kiwix Plug Installer
This software will assist you in installing and configuring Kiwix for
your plug computer.

Please check that you have the following handy:
* running this software on your plug computer (debian compatible).
* running this software as root.
* you have a USB stick with a ZIM file and search index on it (plugged but not mounted)
* you know the device path for your USB stick (ex: /dev/sdc1)
"

# continue?
check_quit

echo "Good!
The next steps are as follow:
1. Collect configuration information.
2. Install third party programs.
3. Create placeholder for Kiwix binary and configuration file.
4. Download kiwix binary and resources.
5. Edit configuration.
"""

echo -e "** CONFIGURATION\n"

echo "Where do you want to install kiwix-serve?"
echo -n "[$DEFAULT_BINPATH] "
read BINPATH
if ["$BINPATH" = ""]
then
BINPATH=$DEFAULT_BINPATH
fi
echo -e "Kiwix will be installed in $BINPATH\n"

echo "Where do you want to store the landing static web pages?"
echo -n "[$DEFAULT_WWWROOT] "
read WWWROOT
if ["$WWWROOT" = ""]
then
WWWROOT=$DEFAULT_WWWROOT
fi
echo -e "Web pages will be installed in $WWWROOT\n"

echo "What is your USB device ?"
echo -n "[$DEFAULT_USBDEVICE] "
read USBDEVICE
if ["$USBDEVICE" = ""]
then
USBDEVICE=$DEFAULT_USBDEVICE
fi
echo -e "Kiwix will mount your $USBDEVICE USB device as data source\n"

echo "What is your USB mount point ?"
echo -n "[$DEFAULT_USBMOUNTPOINT] "
read USBMOUNTPOINT
if ["$USBMOUNTPOINT" = ""]
then
USBMOUNTPOINT=$DEFAULT_USBMOUNTPOINT
fi
echo -e "USB device with data will be mounted as $USBMOUNTPOINT\n"

echo "What is the file name (not path) of your ZIM file ?"
echo -n "[$DEFAULT_ZIMFILE] "
read ZIMFILE
if ["$ZIMFILE" = ""]
then
ZIMFILE=$DEFAULT_ZIMFILE
fi
echo -e "Kiwix will use $ZIMFILE as ZIM file\n"

echo "What is the file name (not path) of your ZIM index folder ?"
echo -n "[$DEFAULT_ZIMINDEX] "
read ZIMINDEX
if ["$ZIMINDEX" = ""]
then
ZIMINDEX=$DEFAULT_ZIMINDEX
fi
echo -e "Kiwix will use $ZIMINDEX as ZIM index\n"

echo "Does your plug use an uAP WiFi chipset? globascale plug"
echo "You can check that by typing uaputl in a command prompt"
echo -n "[$DEFAULT_USE_UAP] "
read USE_UAP
USE_UAP=echo $USE_UAP | tr '[:upper:]' '[:lower:]'
if [ "$USE_UAP" = "y" ]
then
USE_UAP=1
echo -e "WiFi AP will be configured using uAP\n"
else
USE_UAP=0
fi
echo -e "WiFi AP won't be configured\n"

echo "Installing dependencies now (nginx, wget)"
apt-get install nginx wget udhcpd dnsmasq

echo -e "\n"

echo "creating kiwix placeholder:"
mkdir -p $BINPATH
echo "Downloading Kiwix archive..."
wget -O kiwix-plug.tar $DL_KIWIX_TAR
echo "Extracting kiwix archive..."
tar xf kiwix-plug.tar -C $BINPATH --strip-components=1

echo "Installing nginx configuration"
ROOTPATH="${WWWROOT//\//\/}"
DATAPATH="${USBMOUNTPOINT//\//\/}"
sed -e 's/ROOTPATH/$ROOTPATH/' $BINPATH/kiwix.nginx > /etc/nginx/sites-availables/kiwix
sed -e 's/DATAPATH/$DATAPATH/' /etc/nginx/sites-availables/kiwix > /etc/nginx/sites-availables/kiwix
ln -sf /etc/nginx/sites-availables/kiwix /etc/nginx/sites-enabled/kiwix
rm /etc/nginx/sites-enabled/default

echo "Installing udhcp config"
sed -e 's/IFACE/$IFACE_MASQ/' $BINPATH/udhcp.conf > /etc/udhcpd.conf

# DNSMASQ: using default config.

echo "Mounting USB device"
mount -oumask=000 $USBDEVICE $USBMOUNTPOINT

echo "Copying default web pages to $WWWROOT and $USBMOUNTPOINT"
cp -r $BINPATH/landing/* $WWWROOT/*
sed -e 's/ZIMFILE/$ZIMFILE/' $WWWROOT/index.html > $WWWROOT/index.html
mv $WWWROOT/index.html $USBMOUNTPOINT/index.html
ln -sf $USBMOUNTPOINT/index.html $WWWROOT/index.html

echo "Finalizing"
sed -i -e 's/KIWIX_SSID/$SSID/' $BINPATH/uap.sh
sed -i -e 's/IFACE/$IFACE_MASQ/' $BINPATH/uap.sh

sed -i -e 's/USBDEVICE/$USBDEVICE/' $BINPATH/launch.sh
sed -i -e 's/USBMOUNTPOINT/$USBMOUNTPOINT/' $BINPATH/launch.sh
sed -i -e 's/BINPATH/$BINPATH/' $BINPATH/launch.sh
sed -i -e 's/ZIMINDEX/$ZIMINDEX/' $BINPATH/launch.sh
sed -i -e 's/ZIMFILE/$ZIMFILE/' $BINPATH/launch.sh

echo "Done. Add the following to your /etc/rc.local file"
echo "###"
if [ $USE_UAP ]
then
    echo "$BINPATH/uap.sh"
fi
echo "$BINPATH/launch.sh"
echo "###"

echo "Once it's done, reboot!"

