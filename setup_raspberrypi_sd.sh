#!/bin/bash

# RASPBIAN_IMAGE_URL=http://download.kiwix.org/dev/raspbian_lite_latest.zip
# John - update raspian image
RASPBIAN_IMAGE_URL=https://downloads.raspberrypi.org/raspbian_lite_latest

# Compute script path
BINARY_ORG="$0"
if [ ! ${BINARY_ORG:0:1} = "/" ]
then
   BINARY_ORG=`pwd`/$BINARY_ORG
fi

# Binary target script path (in case of symlink)
BINARY=$BINARY_ORG
while [ `readlink $BINARY` ]
do
    BINARY=`readlink $BINARY`
done

# Compute script dir ($ROOT)
if [ ${BINARY:0:1} = "/" ]
then
    ROOT=`dirname $BINARY`
else
    ROOT=`dirname $BINARY_ORG`/`dirname $BINARY`
    ROOT=`cd $ROOT ; pwd`
fi

# Check if the DNS works
`host -a www.kiwix.org 8.8.8.8 > /dev/null`
EXIT_VALUE=$?
if [ ! "$EXIT_VALUE" = "0" ]
then
    echo "Was not able to resolve www.kiwix.org. Are you access to Internet is OK?"
    exit 1
fi

# Check if the access to Internet works
`ping -c3 www.kiwix.org > /dev/null`
EXIT_VALUE=$?
if [ ! "$EXIT_VALUE" = "0" ]
then
    echo "Was not able to ping www.kiwix.org. Are you access to Internet is OK?"
    BIN_TO_INSTALL="yes"
fi

# Check if "wget" is installed
WGET=`whereis -b wget | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$WGET" = "" ]
then
    echo "You need to install wget (apt-get install wget)."
    BIN_TO_INSTALL="yes"
fi

# Check if "unzip" is installed
UNZIP=`whereis -b unzip | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$UNZIP" = "" ]
then
    echo "You need to install unzip (apt-get install unzip)."
    BIN_TO_INSTALL="yes"
fi

# Check if packages need to be installed
if [ "$BIN_TO_INSTALL" = "yes" ]
then
    echo "You need to install thus packages before going further..."
    exit 1
fi

# Download GNU/Linux static (for kiwix-index)
if [ ! -f "$ROOT/bin/.raspbian_lite_latest.zip.finished" -o  ! -f "$ROOT/bin/kiwix.tar.bz2" ]
then
    rm -f "$ROOT/bin/.raspbian_lite_latest.zip.finished" "$ROOT/bin/raspbian_lite_latest.zip"
    wget -c $RASPBIAN_IMAGE_URL -O "$ROOT/bin/raspbian_lite_latest.zip"
    cd "$ROOT/bin/" ; unzip "$ROOT/bin/raspbian_lite_latest.zip" ; cd ../
    touch "$ROOT/bin/.raspbian_lite_latest.zip.finished"
fi

# Retrieve the SD card device
DEVICE=$1
if [ "$DEVICE" == "" ]
then
    echo "please specify a device (not a partition) where to install the system, eg /dev/sdb"
    exit 1
else
    echo "kiwix-plug system will be installed on $DEVICE..."
fi

# Copying the image to the SD card
RASPBIAN_IMG=`find bin -name "*raspbian*.img" | xargs ls -r -1 | head -n1`
echo "Copying the image $RASPBIAN_IMG to the SD card..."
sudo dd if=$RASPBIAN_IMG of=$DEVICE bs=1M

# Formating the rest of the SD card partition in EXT4
# No.  Just use raspi-config --expand-rootfs to expand it once the pi comes up.
# Otherwise
# a) we don't have enough space on the root fs to add all the programs we'll probably want
# b) we'll waste space via multiple partitions.  I've no really good reason to divide the storage,
#    except perhaps to avoid filling the sd card with log messages from nginx - but for me now,
#    that's not a big drama.
# sudo umount ${DEVICE}1
# sudo umount ${DEVICE}2
# sudo umount ${DEVICE}3
# sudo umount ${DEVICE}4
# (echo n; echo p; echo ; echo ; echo ; echo w) | sudo fdisk ${DEVICE}
# (echo n; echo p; echo ; echo ; echo ; echo w) | sudo fdisk ${DEVICE}
# (echo d; echo 3; echo w) | sudo fdisk ${DEVICE}
# sudo mkfs.ext4 -F ${DEVICE}4
# DIR=/tmp/tmp_mnt$$
# sudo mkdir -p $DIR
# sudo mount ${DEVICE}4 $DIR
# sudo rm -rf $DIR/*
# sudo umount $DIR
# sudo rmdir $DIR
