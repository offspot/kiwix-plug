#!/bin/bash

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

# Detect USB storage
IFS=$'\n'
for MOUNT in `df | sed "s/^ *//;s/ *$//;s/ \{1,\}/ /g" | cut --delimiter=" " -f6- | grep "/media/"`
do
    if [ "$(ls -A "$MOUNT")" = "" ]
    then
	echo "Empty removable device found at $MOUNT. This will be used to install kiwix-plug."
	DEVICE=`df | sed "s/^ *//;s/ *$//;s/ \{1,\}/ /g" | grep "$MOUNT" | cut --delimiter=" " -f1`
	break
    fi
    MOUNT=
done
unset IFS

# Check if an empty removable device was found
if [ "$MOUNT" = "" ]
then
    echo "Unable to find an empty removable device. Are you sure you have put a USB key to your computer?"
    exit 1
fi

# Set USB label
sudo umount "$DEVICE"
MKDOSFS=`whereis mkdosfs | cut -d" " -f2`
$MKDOSFS -n KIWIX "$DEVICE"
sudo mount "$DEVICE" "$MOUNT"

# Copy the data files
cp --verbose -r "$ROOT/data/" "$MOUNT"

# Create system directory
mkdir "$MOUNT/system/"

# Copy system kiwix-plug script
cp --verbose "$ROOT/scripts/kiwix-plug.usbkey" "$MOUNT/system/kiwix-plug"
chmod +x "$MOUNT/system/kiwix-plug"

# Copy the binaries
mkdir "$MOUNT/system/bin/"
cp --verbose "$ROOT/bin/kiwix-serve" "$MOUNT/system/bin/"

# Copy the binaries packages
mkdir "$MOUNT/packages/"
cp --verbose "$ROOT/bin/kiwix.tar.bz2" "$MOUNT/packages/"
cp --verbose "$ROOT/bin/kiwix.dmg" "$MOUNT/packages/"
cp --verbose "$ROOT/bin/kiwix.zip" "$MOUNT/packages/"
cp --verbose "$ROOT/bin/kiwix-src.tar.gz" "$MOUNT/packages/"

# Copy the landing HTML pages
mkdir "$MOUNT/system/landing/"
cp -r --verbose "$ROOT/landing" "$MOUNT/system/"

# Copy the configuration scripts
mkdir "$MOUNT/system/conf/"
cp -r --verbose "$ROOT/conf/" "$MOUNT/system/"

# Remove useless files & directories
find "$MOUNT" -name ".svn" -exec /bin/rm -rf '{}' \;
find "$MOUNT" -name ".finished" -exec /bin/rm -rf '{}' \;

# Create log & stats & share directories
mkdir "$MOUNT/log/"
mkdir "$MOUNT/stats/"
mkdir "$MOUNT/goinfre/"

# Flush everything on the USB drive
sync
