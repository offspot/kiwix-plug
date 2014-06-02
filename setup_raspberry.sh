#!/bin/sh

# List deb packages to check/install:
# apt-get -o DPkg::options::=--force-confmiss --assume-yes install dialog install dnsmasq-base awstats nginx wireless-tools ntpdate

# Init a few variables
SSH_LOGIN=pi
SSH_PASS=raspberry
COMMANDS=/tmp/setup_plug_commands.sh

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

check_package() {
  if [ "$3" = "soft" ] ; then
    PKG=\`dpkg -l $1 | grep ^ii\`
  else
    PKG=\`whereis $1 | cut --delimiter=":" -f2 | cut --delimiter=" " -f2\`
  fi
  if [ "$PKG" = "" ]
  then
    echo "Installing $1..."
    sudo apt-get update
    sudo apt-get $4 --assume-yes install $2
    if [ "$?" != "0" ]
    then
      echo "Unable to install correctly $1"
      exit 1
    else
      echo "$1 installation successful"
    fi
  else
    echo "$1 is already installed."
  fi
}

# Check if we are on the Raspberry Pi
if [ "`cat /etc/issue | cut -c1-8`" = "Raspbian" ] ; then
  
  # Install required packages
  dpkg --configure -a
  install_package dialog  dialog       soft
  install_package dnsmasq dnsmasq-base hard
  install_package awstats awstats      soft
  install_package nginx   nginx        hard "-o DPkg::options::=--force-confmiss"
  install_package hostapd hostapd      soft
  
  # Setup the init.d script
  sudo cp scripts/kiwix-plug.plug /etc/init.d/kiwix-plug
  IN_RC_LOCAL=\`grep "/etc/init.d/kiwix-plug" /etc/rc.local\`
  if [ "$IN_RC_LOCAL" = "" ]
  then
    echo "Updating /etc/rc.local..."
    sudo sed -i -e 's/exit 0//' /etc/rc.local
    sudo echo "" >> /etc/rc.local
    sudo echo "/etc/init.d/kiwix-plug start" >> /etc/rc.local
    sudo echo "" >> /etc/rc.local
    sudo echo "exit 0" >> /etc/rc.local
  else
    echo "rc.local already updated"
  fi
  sudo chmod +x /etc/init.d/kiwix-plug
  sudo chmod +x /etc/rc.local
  
  # Avoid ubsmount mounting a flashdrive with a 077 umask
  if [ -f "/etc/usbmount/usbmount.conf" ]
  then
    sudo sed -i "s/umask=077/umask=022/g" /etc/usbmount/usbmount.conf
  else
    echo "no usbmount config file to patch"
  fi
  
else

# Find the IP of the plug
IP=`sudo arp-scan --localnet | grep 'b8:27:eb' | cut -s -f1 | tail -n1`
if [ "$IP" = "" ]
then
    echo "Unable to find the IP of the Raspberry Pi on your local network."
    exit 1
else
    echo "The IP of the Raspberry Pi is $IP"
fi

# Copy init.d script
pscp -pw "$SSH_PASS" scripts/kiwix-plug.plug "$SSH_LOGIN@$IP:/tmp/kiwix-plug" <<EOF
n
EOF

# Write remote commands in a file
echo "                                                                                     \n\
echo \"\"                                                                                  \n\
if [ ! \"`cat /etc/issue | cut -c1-8`\" = \"Raspbian\" ] ; then                            \n\
  echo \"Fatal error: this device has not Raspbian. Abort.\"                               \n\
  exit 1                                                                                   \n\
fi                                                                                         \n\
echo \"Successfuly connected to the Raspberry Pi...\"                                      \n\
" > $COMMANDS

# Move kiwix-plug to its final location
echo "
sudo mv /tmp/kiwix-plug /etc/init.d/kiwix-plug                                             \n\
" > $COMMANDS

# Setup the environement variable for non-interactive tty
echo "                                                                                     \n\
export DEBIAN_FRONTEND=noninteractive                                                      \n\
" >> $COMMANDS

# For security reason run dpkg
echo "                                                                                     \n\
sudo dpkg --configure -a                                                                   \n\
" >> $COMMANDS

# Check if dialog is there and install it otherwise
echo "                                                                                     \n\
DIALOG=\`dpkg -l dialog | grep ^ii\`                                                       \n\
if [ \"\$DIALOG\" = \"\" ]                                                                 \n\
then                                                                                       \n\
  echo \"Installing dialog...\"                                                            \n\
  sudo apt-get update                                                                      \n\
  sudo apt-get --assume-yes install dialog                                                 \n\
  if [ \"$?\" != \"0\" ]                                                                   \n\
  then                                                                                     \n\
    echo \"Unable to install correctly dialog\"                                            \n\
    exit 1                                                                                 \n\
  else                                                                                     \n\
    echo \"dialog installation successful\"                                                \n\
  fi                                                                                       \n\
else                                                                                       \n\
  echo \"dialog is already installed.\"                                                    \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if dnsmasq is there and install it otherwise
echo "                                                                                     \n\
DNSMASQ=\`whereis dnsmasq | cut --delimiter=\":\" -f2 | cut --delimiter=\" \" -f2\`        \n\
if [ \"\$DNSMASQ\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing dnsmasq...\"                                                           \n\
  sudo apt-get update                                                                      \n\
  sudo apt-get --assume-yes install dnsmasq-base                                           \n\
  if [ \"$?\" != \"0\" ]                                                                   \n\
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

# Check if awstats is installed
echo "                                                                                     \n\
AWSTATS=\`dpkg -l awstats | grep ^ii\`                                                     \n\
if [ \"\$AWSTATS\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing awstats...\"                                                           \n\
  sudo apt-get update                                                                      \n\
  sudo apt-get --assume-yes install awstats                                                \n\
  if [ \"$?\" != \"0\" ]                                                                   \n\
  then                                                                                     \n\
    echo \"Unable to install correctly awstats\"                                           \n\
    exit 1                                                                                 \n\
  else                                                                                     \n\
    echo \"awstats installation successful\"                                               \n\
  fi                                                                                       \n\
else                                                                                       \n\
  echo \"awstats is already installed.\"                                                   \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if nginx is there and install it otherwise
echo "                                                                                     \n\
NGINX=\`whereis nginx | cut --delimiter=\":\" -f2 | cut --delimiter=\" \" -f2\`            \n\
if [ \"\$NGINX\" = \"\" ]                                                                  \n\
then                                                                                       \n\
  echo \"Installing nginx...\"                                                             \n\
  sudo apt-get update                                                                      \n\
  sudo apt-get -o DPkg::options::=--force-confmiss --assume-yes install nginx              \n\
else                                                                                       \n\
  echo \"nginx is already installed.\"                                                     \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if hostapd is there and install it otherwise
echo "                                                                                     \n\
HOSTAPD=\`dpkg -l hostapd | grep ^ii\`                                                     \n\
if [ \"\$HOSTAPD\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing hostapd...\"                                                           \n\
  sudo apt-get update                                                                      \n\
  sudo apt-get --assume-yes install hostapd                                                \n\
  if [ \"$?\" != \"0\" ]                                                                   \n\
  then                                                                                     \n\
    echo \"Unable to install correctly hostapd\"                                           \n\
    exit 1                                                                                 \n\
  else                                                                                     \n\
    echo \"hostapd installation successful\"                                               \n\
  fi                                                                                       \n\
else                                                                                       \n\
  echo \"hostapd is already installed.\"                                                   \n\
fi                                                                                         \n\
" >> $COMMANDS

# Setup the init.d script
echo "                                                                                     \n\
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
echo "                                                                                     \n\
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

fi

# End music
beep -f 659 -l 460 -n -f 784 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 880 -l 230 -n -f 659 -l 230 -n -f 587 -l 230 -n -f 659 -l 460 -n -f 988 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 1047 -l 230 -n -f 988 -l 230 -n -f 784 -l 230 -n -f 659 -l 230 -n -f 988 -l 230 -n -f 1318 -l 230 -n -f 659 -l 110 -n -f 587 -l 230 -n -f 587 -l 110 -n -f 494 -l 230 -n -f 740 -l 230 -n -f 659 -l 460
