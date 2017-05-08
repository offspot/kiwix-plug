#!/usr/bin/env python

#     Copyright 2013 Claudio d'Angelis <claudiodangelis@gmail.com>
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#             http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.

import os
import glib
import gudev
import sys
import argparse
import pickle

__version__ = "0.1.0"
__author__  = "Claudio d'Angelis <claudiodangelis@gmail.com>"

# Configuration
config_file = "~/.unplug2shutdownrc"

# Main class of application
class Main:
    def __init__(self,args):
        self.configure = args.configure
        # Check if configuration file exists and if user doesn't want to reconf
        if os.path.exists(os.path.expanduser(config_file)) and self.configure\
         is False:
            # File exists
            # Read the info of the device you're looking for
            self.device_info = pickle.load(open(os.path.expanduser(config_file),
              'rb'))
            result = self.watch_removed_device()
            if result:
                os.system("shutdown -h now")

        elif self.configure:
            # User wants to reconfigure
            self.launch_configuration_process()
        else:
        # File does not exists, start calibration
            self.launch_configuration_process()

    def watch_removed_device(self):
        # look for removed device
        loop = glib.MainLoop()
        device_listener = DeviceListener(self,loop,"remove")

        client = gudev.Client(["usb/usb_device"])
        client.connect("uevent", device_listener.callback, None)

        loop.run()
        return device_listener.device_found

    def configure_device(self):
        # binding process starts here
        loop = glib.MainLoop()
        device_listener = DeviceListener(self,loop,'add')

        client = gudev.Client(["usb/usb_device"])
        client.connect("uevent", device_listener.callback, None)

        loop.run()
        return device_listener.device_info

    def launch_configuration_process(self):
        print ("Please connect the USB device you want to use as handler to "
        "shutdown your Raspberry Pi.\n"
        "It could be anything: a Flash Disk, MMC Adapter, Wireless Adapter,"
        " etc.\n")
        sys.stdout.flush()

        result = self.configure_device()
        pickle.dump(result, open(os.path.expanduser(config_file) , "wb"))

        print "Configuration have been saved."
        print "RaspberryPi will shutdown by removing: " + result["ID_MODEL"]
        print "Bye!"
        sys.stdout.flush()

class DeviceListener:
    def __init__(self,app,loop,event):
        self.loop = loop
        self.app = app
        self.event = event
        self.device_info = {}

    def callback(self, client, action, device, user_data):
        device_model = device.get_property("ID_MODEL")
        device_serial = device.get_property("ID_SERIAL")

        # if we're looking for 'add', this will ignore 'remove' and viceversa
        if action == self.event:
            if self.event == "add":
                # TODO: formatting and replace with better text
                print "You added/selected this device:\n"
                print "    "+device_model
                print "    "+device_serial
                self.device_info["ID_MODEL"] = device_model
                self.device_info["ID_SERIAL"] = device_serial
                self.device_info["ID_VENDOR"] = device.get_property("ID_VENDOR")
                self.device_info["PRODUCT"] = device.get_property("PRODUCT")
                self.loop.quit()
                return self.device_info
            else:
                # removed device event:
                print "You removed/de-selected this device:\n"
                print "    "+device_model
                print "    "+device_serial
                self.device_info["ID_MODEL"] = device_model
                self.device_info["ID_SERIAL"] = device_serial
                self.device_info["ID_VENDOR"] = device.get_property("ID_VENDOR")
                self.device_info["PRODUCT"] = device.get_property("PRODUCT")
                if self.device_info == self.app.device_info:
                    self.loop.quit()
                    self.device_found = True
                    return self.device_found

parser = argparse.ArgumentParser()
parser.add_argument(
    "--configure",
    help="configure the device to be used and exit",
    action="store_true")

app = Main(parser.parse_args())
