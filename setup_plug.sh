#!/bin/sh

# Init a few variables
SSH_LOGIN=root
SSH_PASS=nosoup4u
COMMANDS=/tmp/setup_plug_commands.sh

# Check if "arp-scan" is installed
ARP_SCAN=`whereis arp-scan | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$ARP_SCAN" = "" ]
then
    echo "You need to install arp-scan (apt-get install arp-scan)."
    exit 1
fi

# Check if "plink" is installed
PLINK=`whereis plink | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$PLINK" = "" ]
then
    echo "You need to install plink (apt-get install putty-tools)."
    exit 1
fi

# Find the IP of the plug
IP=`sudo arp-scan --localnet | grep "f0:ad:4e" | cut -s -f1 | tail -n1`
if [ "$IP" = "" ]
then
    echo "Unable to find the IP of the plug on your local network."
    exit 1
else
    echo "The IP of the plug is $IP"
fi

# Write remote commands in a file
echo "                                                                                     \n\
echo \"\"                                                                                  \n\
echo \"Successfuly connected to the plug...\"                                              \n\
" > $COMMANDS

# For security reason run dpkg
echo "                                                                                     \n\
dpkg --configure -a                                                                        \n\
" >> $COMMANDS

# Check if dnsmasq is there and install it otherwise
echo "                                                                                     \n\
DNSMASQ=\`whereis dnsmasq | cut --delimiter=\":\" -f2 | cut --delimiter=\" \" -f2\`        \n\
if [ \"\$DNSMASQ\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing dnsmasq...\"                                                           \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install dnsmasq-base                                                \n\
else                                                                                       \n\
  echo \"dnsmasq is already installed.\"                                                   \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if nginx is there and install it otherwise
echo "                                                                                     \n\
NGINX=\`whereis nginx | cut --delimiter=\":\" -f2 | cut --delimiter=\" \" -f2\`            \n\
if [ \"\$NGINX\" = \"\" ]                                                                  \n\
then                                                                                       \n\
  echo \"Installing nginx...\"                                                             \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install nginx                                                       \n\
else                                                                                       \n\
  echo \"nginx is already installed.\"                                                     \n\
fi                                                                                         \n\
" >> $COMMANDS

# Connect the plug per ssh and run a few commands
"$PLINK" -ssh -pw "$SSH_PASS" "$SSH_LOGIN@$IP" -m $COMMANDS <<EOF
n
EOF
