#!/bin/bash

echo Launching Kiwix
mount -oumask=000 USBDEVICE USBMOUNTPOINT
sleep 4
BINPATH/kiwix-serve --library --port=4201 --daemon USBMOUNTPOINT/library.xml
