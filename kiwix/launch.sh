#!/bin/bash

echo Launching Kiwix
mount -oumask=000 USBDEVICE USBMOUNTPOINT
sleep 4
BINPATH/kiwix-serve --index=USBMOUNTPOINT/ZIMINDEX --port=4201 --daemon USBMOUNTPOINT/ZIMFILE
