#!/bin/bash

KIWIX_STATIC_URL=http://download.kiwix.org/bin/nightly/2012-07-01/kiwix-20120701_r3740-static-i686.tar.bz2

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
    DO_CLEAN=1
else
    echo "Do not re-download already present files"
fi

# Download GNU/Linux static (for kiwix-index)
wget -c $KIWIX_STATIC_URL -O $ROOT/bin/kiwix-x86.tar.bz2
cd $ROOT/bin/ ; tar -xvjf $ROOT/bin/kiwix-x86.tar.bz2 ; cd ../