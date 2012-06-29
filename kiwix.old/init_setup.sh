#!/bin/sh

# This is called from /etc/rc.local to perform the initial setup.

# We always bootup in AP mode. Delete any stale files
rm -f /etc/wlanclient.mode
#SSID=dream-uAP-`ifconfig uap0 | awk -F ":" '/HWaddr/ {print $6$7}'`
SSID=Wikpedia

insmod /root/uap8xxx.ko
#ifconfig uap0 192.168.1.1 up
#ifconfig eth1 192.168.1.1 up
/usr/bin/uaputl sys_cfg_ssid $SSID
/usr/bin/uaputl bss_start
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
iptables -t nat -A POSTROUTING -o uap0 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
#/etc/init.d/udhcpd start
dhcpd
/etc/init.d/dnsmasq start
iptables -A INPUT -i uap0 -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -i eth1 -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -i uap0 -p tcp -m tcp --dport 4201 -j ACCEPT
iptables -A INPUT -i eth1 -p tcp -m tcp --dport 4201 -j ACCEPT

# Re-enable bluetooth. In the earlier case, it didn't find the firmware.
#rmmod libertas_sdio libertas btmrvl_sdio btmrvl bluetooth 2>/dev/null
# reg: disable BT to save power
# rmmod btmrvl_sdio btmrvl
# /etc/init.d/bluetooth start

# modprobe btmrvl_sdio
# hciconfig hci0 up
# hciconfig hci0 piscan
# /usr/bin/mute-agent &

#blinkled >> /dev/null
blinkbtled 0xf1010148 w 0x000

echo Launching Kiwix
mount -oumask=000 /dev/sdc1 /media/usb2/
sleep 4
/root/kiwix/server/kiwix-serve --library --port=4201 --daemon /media/usb2/library.xml

/root/check_status.sh