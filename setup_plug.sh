#!/bin/sh

# Init a few variables
SSH_LOGIN=root
SSH_PASS=nosoup4u
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

# Find the IP of the plug
IP=`sudo arp-scan --localnet | grep -E '^f0:ad:4e|40:2c:f4' | cut -s -f1 | tail -n1`
if [ "$IP" = "" ]
then
    echo "Unable to find the IP of the plug on your local network."
    exit 1
else
    echo "The IP of the plug is $IP"
fi

# Copy init.d script
pscp -pw "$SSH_PASS" scripts/kiwix-plug.plug "$SSH_LOGIN@$IP:/etc/init.d/kiwix-plug" <<EOF
n
EOF

# Write remote commands in a file
echo "                                                                                     \n\
echo \"\"                                                                                  \n\
echo \"Successfuly connected to the plug...\"                                              \n\
" > $COMMANDS

# Setup the environement variable for non-interactive tty
echo "                                                                                     \n\
export DEBIAN_FRONTEND=noninteractive                                                      \n\
" >> $COMMANDS

# For security reason run dpkg
echo "                                                                                     \n\
dpkg --configure -a                                                                        \n\
" >> $COMMANDS

# Check if dialog is there and install it otherwise
echo "                                                                                     \n\
DIALOG=\`dpkg -l dialog | grep ii\`                                                        \n\
if [ \"\$DIALOG\" = \"\" ]                                                                 \n\
then                                                                                       \n\
  echo \"Installing dialog...\"                                                            \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install dialog                                                      \n\
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
  apt-get update                                                                           \n\
  apt-get --assume-yes install dnsmasq-base                                                \n\
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
AWSTATS=\`dpkg -l awstats | grep ii\`                                                      \n\
if [ \"\$AWSTATS\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing awstats...\"                                                           \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install awstats                                                     \n\
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
  apt-get update                                                                           \n\
  apt-get -o DPkg::options::=--force-confmiss --assume-yes install nginx                   \n\
else                                                                                       \n\
  echo \"nginx is already installed.\"                                                     \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if wireless-tools is installed
echo "                                                                                     \n\
WTOOLS=\`dpkg -l wireless-tools | grep ii\`                                                \n\
if [ \"\$WTOOLS\" = \"\" ]                                                                 \n\
then                                                                                       \n\
  echo \"Installing wireless-tools...\"                                                    \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install wireless-tools                                              \n\
  if [ \"$?\" != \"0\" ]                                                                   \n\
  then                                                                                     \n\
    echo \"Unable to install correctly dialog\"                                            \n\
    exit 1                                                                                 \n\
  else                                                                                     \n\
    echo \"dialog installation successful\"                                                \n\
  fi                                                                                       \n\
else                                                                                       \n\
  echo \"wireless-tools are already installed.\"                                           \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if ntpdate is installed and update the clock (ntpdate-debian)
echo "                                                                                     \n\
NTPDATE=\`dpkg -l ntpdate | grep ii\`                                                      \n\
if [ \"\$NTPDATE\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing ntpdate...\"                                                           \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install ntpdate                                                     \n\
  if [ \"$?\" != \"0\" ]                                                                   \n\
  then                                                                                     \n\
    echo \"Unable to install correctly ntpdate\"                                           \n\
    exit 1                                                                                 \n\
  else                                                                                     \n\
    echo \"ntpdate installation successful\"                                               \n\
  fi                                                                                       \n\
else                                                                                       \n\
  echo \"ntpdate is already installed.\"                                                   \n\
fi                                                                                         \n\
ntpdate-debian                                                                             \n\
" >> $COMMANDS

# Setup the init.d script
echo "                                                                                     \n\
IN_RC_LOCAL=\`grep \"/etc/init.d/kiwix-plug\" /etc/rc.local\`                              \n\
if [ \"\$IN_RC_LOCAL\" = \"\" ]                                                            \n\
then                                                                                       \n\
  echo \"Updating /etc/rc.local...\"                                                       \n\
  sed -i -e 's/exit 0//' /etc/rc.local                                                     \n\
  echo \"\" >> /etc/rc.local                                                               \n\
  echo \"/etc/init.d/kiwix-plug start\" >> /etc/rc.local                                   \n\
  echo \"\" >> /etc/rc.local                                                               \n\
else                                                                                       \n\
  echo \"rc.local already updated\"                                                        \n\
fi                                                                                         \n\
chmod +x /etc/init.d/kiwix-plug                                                            \n\
chmod +x /etc/rc.local                                                                     \n\
" >> $COMMANDS

# Avoid ubsmount mounting a flashdrive with a 077 umask
echo "                                                                                     \n\
if [ -f \"/etc/usbmount/usbmount.conf\" ]                                                  \n\
then                                                                                       \n\
  sed -i \"s/umask=077/umask=022/g\" /etc/usbmount/usbmount.conf                              \n\
else                                                                                       \n\
  echo \"no usbmount config file to patch\"                                                \n\
fi                                                                                         \n\
" >> $COMMANDS

# Connect the plug per ssh and run a few commands
plink -ssh -pw "$SSH_PASS" "$SSH_LOGIN@$IP" -m $COMMANDS <<EOF
n
EOF

# End music
beep -f 659 -l 460 -n -f 784 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 880 -l 230 -n -f 659 -l 230 -n -f 587 -l 230 -n -f 659 -l 460 -n -f 988 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 1047 -l 230 -n -f 988 -l 230 -n -f 784 -l 230 -n -f 659 -l 230 -n -f 988 -l 230 -n -f 1318 -l 230 -n -f 659 -l 110 -n -f 587 -l 230 -n -f 587 -l 110 -n -f 494 -l 230 -n -f 740 -l 230 -n -f 659 -l 460
