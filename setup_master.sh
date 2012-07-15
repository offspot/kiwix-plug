#!/bin/bash

KIWIX_X86_STATIC_URL=http://download.kiwix.org/bin/0.9_rc1/kiwix-0.9-rc1-linux-i686.tar.bz2
KIWIX_WINDOWS_URL=http://download.kiwix.org/bin/0.9_rc1/kiwix-0.9-rc1-win.zip
KIWIX_OSX_URL=http://download.kiwix.org/bin/0.9_rc1/kiwix-0.9-rc1.dmg
KIWIX_ARM_STATIC_URL=http://download.kiwix.org/bin/0.9_rc1/kiwix-server-0.9-rc1-linux-armv5tejl.tar.bz2
KIWIX_SRC_URL=http://download.kiwix.org/src/kiwix-0.9-rc1-src.tar.gz

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
    rm -rf $ROOT/bin/kiwix* $ROOT/bin/.kiwix-*
    rm -rf $ROOT/data/library/library.xml
    rm -rf $ROOT/data/index/*.idx
else
    echo "Do not re-download already present files"
fi

# Download GNU/Linux static (for kiwix-index)
if [ ! -f "$ROOT/bin/.kiwix.tar.bz2.finished" ]
then
    wget -c $KIWIX_X86_STATIC_URL -O "$ROOT/bin/kiwix.tar.bz2"
    cd "$ROOT/bin/" ; tar -xvjf "$ROOT/bin/kiwix.tar.bz2" ; cd ../
    touch "$ROOT/bin/.kiwix.tar.bz2.finished"
fi

# Download ARM static (for the kiwix-serve to install)
if [ ! -f "$ROOT/bin/.kiwix-arm.tar.bz2.finished" ]
then
    wget -c $KIWIX_ARM_STATIC_URL -O "$ROOT/bin/kiwix-arm.tar.bz2"
    cd $ROOT/bin/ ; tar -xvjf "$ROOT/bin/kiwix-arm.tar.bz2" ; cd ../
    touch "$ROOT/bin/.kiwix-arm.tar.bz2.finished"
fi

# Download Kiwix for Windows
if [ ! -f "$ROOT/bin/.kiwix.zip.finished" ]
then
    wget -c $KIWIX_WINDOWS_URL -O "$ROOT/bin/kiwix.zip"
    touch "$ROOT/bin/.kiwix.zip.finished"
fi

# Download Kiwix for OSX
if [ ! -f "$ROOT/bin/.kiwix.dmg.finished" ]
then
    wget -c $KIWIX_OSX_URL -O "$ROOT/bin/kiwix.dmg"
    touch "$ROOT/bin/.kiwix.dmg.finished"
fi

# Download the sources
if [ ! -f "$ROOT/bin/.kiwix-src.tar.gz.finished" ]
then
    wget -c $KIWIX_SRC_URL -O "$ROOT/bin/kiwix-src.tar.gz"
    touch "$ROOT/bin/.kiwix-src.tar.gz.finished"
fi

# Check if there is ZIM files in the /data/content
ZIMS=`find "$ROOT/data/content/" -name "*.zim" ; find "$ROOT/data/content/" -name "*.zimaa"`
if [ "$ZIMS" = "" ]
then
    echo "Please put ZIM files in /data/content"
    exit 1
else
    for ZIM in `find "$ROOT/data/content/" -name "*.zim" -size +2G`
    do
	echo "Splitting $ZIM in parts of 2GB..."
	split --bytes=2000M "$ZIM" "$ZIM"
	rm "$ZIM"
    done
fi

# Rename the ZIM files by adding a "_" at the beginning
for FILE in `find "$ROOT/data/content/" -name "*.zim*" ; find "$ROOT/data/content/" -name "*.zimaa"`
do
    DIRNAME=`dirname "$FILE"`
    BASENAME=`basename "$FILE"`
    if [ ${BASENAME:0:1} != "_" ]
    then
	mv "$FILE" "$DIRNAME/_$BASENAME"
    fi
done

# Index all ZIM files
for ZIM in `find "$ROOT/data/content/" -name "*.zim" ; find "$ROOT/data/content/" -name "*.zimaa"`
do
    ZIM=`echo "$ZIM" | sed -e s/\.zimaa/.zim/`
    BASENAME=`echo "$ZIM" | sed -e "s/.*\///"`
    IDX="$ROOT/data/index/$BASENAME.idx"
    if [ -f "$IDX/.finished" ]
    then
	echo "Index of $ZIM already created"
    else
	echo "Indexing $ZIM at $IDX ..."
	rm -rf "$IDX"
	"$ROOT/bin/kiwix/bin/kiwix-index" --verbose --backend=xapian "$ZIM" "$IDX"
	touch "$IDX/.finished"
    fi
done

# Create the library file "library.xml"
LIBRARY="$ROOT/data/library/library.xml"
rm -f "$LIBRARY"
echo "Recreating library at '$LIBRARY'"
for ZIM in `find "$ROOT/data/content/" -name "*.zim" ; find "$ROOT/data/content/" -name "*.zimaa"`
do
    ZIM=`echo "$ZIM" | sed -e s/\.zimaa/.zim/`
    BASENAME=`echo "$ZIM" | sed -e "s/.*\///"`
    IDX="$BASENAME.idx"
    echo "Adding $ZIM to library.xml"
    "$ROOT/bin/kiwix/bin/kiwix-manage" "$LIBRARY" add "$ZIM" --zimPathToSave="../content/$BASENAME" --indexBackend=xapian --indexPath="../index/$IDX"
done

