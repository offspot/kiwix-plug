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
    echo "please specify a device path where to install the system"
else
    echo "kiwix-plug system will be installed on $DEVICE..."
    sleep 5
fi

# Copying the image to the SD card
RASPBIAN_IMG=`find bin -name "*raspbian*.img"`
echo "Copying the image $RASPBIAN_IMG to the SD card..."
sudo dd if=$RASPBIAN_IMG of=$DEVICE bs=1M

# Formating the rest of the SD card partition in EXT4
sudo umount /dev/sdb1
sudo umount /dev/sdb2
sudo umount /dev/sdb3
sudo umount /dev/sdb4
(echo n; echo p; echo ; echo ; echo ; echo w ; echo q) | sudo fdisk /dev/sdb
(echo n; echo p; echo ; echo ; echo ; echo w ; echo q) | sudo fdisk /dev/sdb
(echo n; echo d; echo 3; echo w ; echo q) | sudo fdisk /dev/sdb
sudo mkfs.ext4 -F /dev/sdb4
sudo mkdir /tmp/tmp_mnt
sudo mount /dev/sdb4 /tmp/tmp_mnt
sudo rm -rf /tmp/tmp_mnt/*
sudo umount /tmp/tmp_mnt
sudo rmdir /tmp/tmp_mnt
