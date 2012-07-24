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
`ping -c3 www.kiwix.org >& /dev/null`
EXIT_VALUE=$?
if [ ! "$EXIT_VALUE" = "0" ]
then
    echo "Was not able to ping www.kiwix.org. Are you access to Internet is OK?"
    exit 1
fi

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

# Check if "pscp" is installed
PSCP=`whereis pscp | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$PSCP" = "" ]
then
    echo "You need to install pscp (apt-get install putty-tools)."
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

# Copy init.d script
"$PSCP" -pw "$SSH_PASS" scripts/kiwix-plug.plug "$SSH_LOGIN@$IP:/etc/init.d/kiwix-plug" <<EOF
n
EOF

# Write remote commands in a file
echo "                                                                                     \n\
echo \"\"                                                                                  \n\
echo \"Successfuly connected to the plug...\"                                              \n\
" > $COMMANDS

# For security reason run dpkg
echo "                                                                                     \n\
dpkg --configure -a                                                                        \n\
" >> $COMMANDS

# Check if dialog is there and install it otherwise
echo "                                                                                     \n\
DIALOG=\`dpkg -l | grep dialog\`                                                           \n\
if [ \"\$DIALOG\" = \"\" ]                                                                 \n\
then                                                                                       \n\
  echo \"Installing dialog...\"                                                            \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install dialog                                                      \n\
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
else                                                                                       \n\
  echo \"dnsmasq is already installed.\"                                                   \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if awstats is installed
echo "                                                                                     \n\
AWSTATS=\`dpkg -l | grep awstats\`                                                         \n\
if [ \"\$AWSTATS\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing awstats...\"                                                           \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install awstats                                                     \n\
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
  apt-get --assume-yes install nginx                                                       \n\
else                                                                                       \n\
  echo \"nginx is already installed.\"                                                     \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if wireless-tools is installed
echo "                                                                                     \n\
WTOOLS=\`dpkg -l | grep wireless-tools\`                                                   \n\
if [ \"\$WTOOLS\" = \"\" ]                                                                 \n\
then                                                                                       \n\
  echo \"Installing wireless-tools...\"                                                    \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install wireless-tools                                              \n\
else                                                                                       \n\
  echo \"wireless-tools are already installed.\"                                           \n\
fi                                                                                         \n\
" >> $COMMANDS

# Check if ntpdate is installed and update the clock (ntpdate-debian)
echo "                                                                                     \n\
NTPDATE=\`dpkg -l | grep ntpdate\`                                                         \n\
if [ \"\$NTPDATE\" = \"\" ]                                                                \n\
then                                                                                       \n\
  echo \"Installing ntpdate...\"                                                           \n\
  apt-get update                                                                           \n\
  apt-get --assume-yes install ntpdate                                                     \n\
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
  echo \"\" >> /etc/rc.local                                                               \n\
  echo \"/etc/init.d/kiwix-plug start\" >> /etc/rc.local                                   \n\
  echo \"\" >> /etc/rc.local                                                               \n\
else                                                                                       \n\
  echo \"rc.local already updated\"                                                        \n\
fi                                                                                         \n\
chmod +x /etc/init.d/kiwix-plug                                                            \n\
" >> $COMMANDS

# Connect the plug per ssh and run a few commands
"$PLINK" -ssh -pw "$SSH_PASS" "$SSH_LOGIN@$IP" -m $COMMANDS <<EOF
n
EOF
