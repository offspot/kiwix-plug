#!/bin/bash

KIWIX_X86_STATIC_URL=http://download.kiwix.org/bin/nightly/2012-07-01/kiwix-20120701_r3740-static-i686.tar.bz2
KIWIX_ARM_STATIC_URL=http://download.kiwix.org/bin/nightly/2012-07-01/kiwix-20120701_r3740-server_armv5tejl.tar.bz2

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

# Check if "wget" is installed
WGET=`whereis wget | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$WGET" = "" ]
then
    echo "You need to install wget (apt-get install wget)."
    exit 1
fi

# Check if "split" is installed
SPLIT=`whereis split | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$SPLIT" = "" ]
then
    echo "You need to install split (apt-get install coreutils)."
    exit 1
fi

# Check if should clean
if [ "$1" == "clean" ]
then
    echo "Remove file before a new downoad"
    `rm -rf $ROOT/bin/kiwix* $ROOT/bin/.kiwix-*`
else
    echo "Do not re-download already present files"
fi

# Download GNU/Linux static (for kiwix-index)
if [ ! -f "$ROOT/bin/.kiwix-x86.tar.bz2.finished" ]
then
    wget -c $KIWIX_X86_STATIC_URL -O "$ROOT/bin/kiwix-x86.tar.bz2"
    cd "$ROOT/bin/" ; tar -xvjf "$ROOT/bin/kiwix-x86.tar.bz2" ; cd ../
    touch "$ROOT/bin/.kiwix-x86.tar.bz2.finished"
fi

# Download ARM static (for the kiwix-serve to install)
if [ ! -f "$ROOT/bin/.kiwix-arm.tar.bz2.finished" ]
then
    wget -c $KIWIX_ARM_STATIC_URL -O "$ROOT/bin/kiwix-arm.tar.bz2"
    cd $ROOT/bin/ ; tar -xvjf "$ROOT/bin/kiwix-arm.tar.bz2" ; cd ../
    touch "$ROOT/bin/.kiwix-arm.tar.bz2.finished"
fi

# Check if there is ZIM files in the /data/content
ZIMS=`find data/content/ -name ".zim"`
if [ "$ZIMS" = "" ]
then
    echo "Please put ZIM files in /data/content"
    exit 1
fi 