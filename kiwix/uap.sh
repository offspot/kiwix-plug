rm -f /etc/wlanclient.mode
SSID=KIWIX_SSID

insmod /root/uap8xxx.ko
ifconfig IFACE 192.168.1.1 up
/usr/bin/uaputl sys_cfg_ssid $SSID
/usr/bin/uaputl bss_start
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
/etc/init.d/udhcpd start
/etc/init.d/dnsmasq start
iptables -A INPUT -i IFACE -p tcp -m tcp --dport 80 -j ACCEPT

