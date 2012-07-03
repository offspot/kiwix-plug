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

# Check if the mtools are installed
MLABEL=`whereis mlabel | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$MLABEL" = "" ]
then
    echo "You need to install the mtools (apt-get install mtools)."
    exit 1
fi

# Detect USB storage
for MOUNT in `df | sed "s/^ *//;s/ *$//;s/ \{1,\}/ /g" | cut --delimiter=" " -f6 | grep "/media/"`
do
    if [ "$(ls -A "$MOUNT")" = "" ]
    then
	echo "Empty removable device found at $MOUNT. This will be used to install kiwix-plug."
	DEVICE=`df | sed "s/^ *//;s/ *$//;s/ \{1,\}/ /g" | grep "$MOUNT" | cut --delimiter=" " -f1`
	break
    fi
done

# Check if an empty removable device was found
if [ "$MOUNT" = "" ]
then
    echo "Unable to find an empty removable device. Are you sure you have put a USB key to your computer?"
fi

# Set USB label
echo "Setting new label KIWIX to USB key at $DEVICE ..."
echo "drive a: file=\"$DEVICE\"" > ~/.mtoolsrc
sudo mlabel a:42
sudo mlabel a:KIWIX
sudo mlabel -s a:
