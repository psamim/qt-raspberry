#!/bin/bash
set -e

echo "Configuring static IP address..."
DHCPCD_CONF="/etc/dhcpcd.conf"
CURRENT_CONF=`cat ${DHCPCD_CONF}`
cat << EOF > ${DHCPCD_CONF}
interface eth0
 static ip_address=192.168.1.89/24
 static routers=192.168.1.1
 static domain_name_servers=8.8.8.8

$CURRENT_CONF
EOF
systemctl daemon-reload
systemctl restart networking
sleep 2
echo "IP static done."

echo "Adding user latinus"
password="freelatinux" # your chosen password
enc_pass=$(perl -e 'printf("%s\n", crypt($ARGV[0], "password"))' "$password")
useradd -m -p ${enc_pass} latinus
echo 'latinus ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/020_latinus-sudo
perl -pi -e 's/--autologin pi/--autologin latinus/g' /etc/systemd/system/getty.target.wants/getty@tty1.service
echo "Adding user done"

# Un-comment deb-src and update
sed -i '/deb-src/s/^#//g'  /etc/apt/sources.list
apt-get update

source ./base.sh
source ./qt.sh


