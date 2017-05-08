#!/bin/bash

# List deb packages to check/install:
# apt-get -o DPkg::options::=--force-confmiss --assume-yes install dialog install dnsmasq-base awstats nginx wireless-tools ntpdate

# Init a few variables
SSH_LOGIN=pi
SSH_PASS=raspberry
COMMANDS=/var/tmp/setup_plug_commands.sh

# Check if the DNS works
`host www.kiwix.org > /dev/null`
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
    exit 1
fi

# Avoid ubsmount mounting a flashdrive with a 077 umask
if [ -f "/etc/usbmount/usbmount.conf" ]
then
    sudo sed -i "s/umask=077/umask=022/g" /etc/usbmount/usbmount.conf
else
    echo "no usbmount config file to patch"
fi

# Find the IP of the plug
# John - Check probable address...
IP=10.22.1.11
if ping -c1 $IP ; then
  echo "The IP of the Raspberry Pi is $IP"
else
  IP=`sudo arp-scan --localnet | grep 'b8:27:eb' | cut -s -f1 | tail -n1`
  if [ "$IP" = "" ]
  then
      echo "Unable to find the IP of the Raspberry Pi on your local network."
      exit 1
  else
      echo "The IP of the Raspberry Pi is $IP"
  fi
fi

# Copy init.d script and unplug2shutdown.py
echo "Connecting to RaspberryPi at IP $IP"
pscp -pw "$SSH_PASS" scripts/kiwix-plug.plug "$SSH_LOGIN@$IP:/tmp/kiwix-plug" <<EOF
n
EOF
pscp -pw "$SSH_PASS" scripts/unplug2shutdown.py "$SSH_LOGIN@$IP:/tmp/" <<EOF
n
EOF

# Write remote commands in a file
echo -e "                                                                                  \n\
echo \"Connected to the the RaspberryPi\"                                                  \n\
export SYSTEM_NAME=\`cat /etc/issue | head -n1 | cut -c1-8\`                               \n\
if [ ! \"\$SYSTEM_NAME\" = \"Raspbian\" ] ; then                                           \n\
  echo \"Fatal error: this device has not Raspbian (\$SYSTEM_NAME found). Abort.\"         \n\
  exit 1                                                                                   \n\
fi                                                                                         \n\
echo \"Successfuly connected to the Raspberry Pi...\"                                      \n\
" > $COMMANDS

# Mount data
echo -e "                                                                                  \n\
echo \"Customizing /etc/fstab...\"                                                         \n\
export IN_FSTAB=\`grep mmcblk0p4 /etc/fstab\`                                              \n\
if [ \"\$IN_FSTAB\" = \"\" ] ; then                                                        \n\
  sudo mkdir /media/data                                                                   \n\
  sudo sh -c \"echo /dev/mmcblk0p4 /media/data ext4 defaults 0 0 >> /etc/fstab\"           \n\
fi                                                                                         \n\
" >> $COMMANDS

# Move kiwix-plug to its final location
echo -e "                                                                                  \n\
sudo mv /tmp/kiwix-plug /etc/init.d/kiwix-plug                                             \n\
sudo mv /tmp/unplug2shutdown.py /usr/local/bin/                                            \n\
echo \"Move kiwix-plug launcher in /etc/init.d/kiwix-plug\"                                \n\
" >> $COMMANDS

# Setup the environement variable for non-interactive tty
echo -e "                                                                                  \n\
export DEBIAN_FRONTEND=noninteractive                                                      \n\
" >> $COMMANDS

# Update package catalog
echo -e "                                                                                   \n\
sudo apt-get update                                                                         \n\
" >> $COMMANDS

# For security reason run dpkg
echo -e "                                                                                  \n\
sudo dpkg --configure -a                                                                   \n\
" >> $COMMANDS

# Check if dnsmasq is there and install it otherwise
echo -e "                                                                                  \n\
DNSMASQ=\`whereis dnsmasq | cut --delimiter=\":\" -f2 | cut --delimiter=\" \" -f2\`        \n\
if [ \"\$DNSMASQ\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing dnsmasq...\"                                                           \n\
  sudo apt-get --assume-yes install dnsmasq-base                                           \n\
  if [ \"\$?\" != \"0\" ]                                                                   \n\
  then                                                                                     \n\
    echo \"Unable to install correctly dnsmasq\"                                           \n\
    exit 1                                                                                 \n\
  else                                                                                     \n\
    echo \"dnsmasq installation successful\"                                               \n\
  fi                                                                                       \n\
else                                                                                       \n\
  echo \"dnsmasq is already installed.\"                                                   \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if nginx is there and install it otherwise
echo -e "                                                                                  \n\
NGINX=\`whereis nginx | cut --delimiter=\":\" -f2 | cut --delimiter=\" \" -f2\`            \n\
if [ \"\$NGINX\" = \"\" ]                                                                  \n\
then                                                                                       \n\
  echo \"Installing nginx...\"                                                             \n\
  sudo apt-get -o DPkg::options::=--force-confmiss --assume-yes install nginx              \n\
else                                                                                       \n\
  echo \"nginx is already installed.\"                                                     \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if various packages are installed
# python-gobject and python-gudev are for unplug2shutdown, a python script to detect when
# a configured usb device is removed, and shutdown the pi - since it has now power off button
echo -e "                                                                                     \n\
for pkg in etckeeper uaputl dialog awstats hostapd inotify-tools firmware-brcm80211 python-gobject python-gudev; do \n\
  FOUND=\`dpkg -l \$pkg | grep ^ii\`                                                          \n\
  if [ \"\$FOUND\" = \"\" ]                                                                   \n\
  then                                                                                        \n\
    echo \"Installing \$pkg...\"                                                              \n\
    sudo apt-get --assume-yes install \$pkg                                                   \n\
    if [ \"\$?\" != \"0\" ]                                                                   \n\
    then                                                                                      \n\
      echo \"Unable to install correctly \$pkg\"                                              \n\
      exit 1                                                                                  \n\
    else                                                                                      \n\
      echo \"\$pkg installation successful\"                                                  \n\
    fi                                                                                        \n\
  else                                                                                        \n\
    echo \"\$pkg is already installed.\"                                                      \n\
  fi                                                                                          \n\
done                                                                                          \n\
" >> $COMMANDS

# Configure unplug2shutdown, by getting the user to insert the USB key
echo -e "                                                                                  \n\
echo \"Configure unplug2shutdown, by inserting the KiwixContent USB key when requested\"   \n\
sudo /usr/local/bin/unplug2shutdown.py --configure                                         \n\
" >> $COMMANDS

# Setup the init.d script
echo -e "                                                                                  \n\
IN_RC_LOCAL=\`grep \"/etc/init.d/kiwix-plug\" /etc/rc.local\`                              \n\
if [ \"\$IN_RC_LOCAL\" = \"\" ]                                                            \n\
then                                                                                       \n\
  echo \"Updating /etc/rc.local...\"                                                       \n\
  sudo sed -i -e 's/exit 0/\\\\n\/etc\/init.d\/kiwix-plug start\\\\n\\\\nexit 0/' /etc/rc.local \n\
else                                                                                       \n\
  echo \"rc.local already updated\"                                                        \n\
fi                                                                                         \n\
sudo chmod +x /etc/init.d/kiwix-plug                                                       \n\
sudo chmod +x /etc/rc.local                                                                \n\
" >> $COMMANDS

# Avoid ubsmount mounting a flashdrive with a 077 umask
echo -e "                                                                                  \n\
if [ -f \"/etc/usbmount/usbmount.conf\" ]                                                  \n\
then                                                                                       \n\
  sudo sed -i \"s/umask=077/umask=022/g\" /etc/usbmount/usbmount.conf                      \n\
else                                                                                       \n\
  echo \"no usbmount config file to patch\"                                                \n\
fi                                                                                         \n\
" >> $COMMANDS

# Connect the plug per ssh and run a few commands
plink -ssh -pw "$SSH_PASS" "$SSH_LOGIN@$IP" -m $COMMANDS <<EOF
n
EOF

# Clear
rm -f $COMMANDS

# End music
beep -f 659 -l 460 -n -f 784 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 880 -l 230 -n -f 659 -l 230 -n -f 587 -l 230 -n -f 659 -l 460 -n -f 988 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 1047 -l 230 -n -f 988 -l 230 -n -f 784 -l 230 -n -f 659 -l 230 -n -f 988 -l 230 -n -f 1318 -l 230 -n -f 659 -l 110 -n -f 587 -l 230 -n -f 587 -l 110 -n -f 494 -l 230 -n -f 740 -l 230 -n -f 659 -l 460
