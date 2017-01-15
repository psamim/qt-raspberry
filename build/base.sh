#!/bin/bash
DEPS="apache2 libapache2-mod-php5 xinit  python-gtk2 python-pip git python-imaging python-dbus redis-server php5-dev sudo python-dev x11-xserver-utils"
PIP_INSTAL="toml redis pyserial wiringpi2"

apt-get install -y ${DEPS}
pip install ${PIP_INSTAL}
perl -pi -e 's/www-data/latinus/g' /etc/apache2/envvars
a2enmod rewrite
service apache2 restart

echo 'Adding udev rules'
UDEV_CONF="/etc/udev/rules.d/80-my-device.rules"
cat << EOF > ${UDEV_CONF}
KERNEL=="ttyUSB[0-9]*", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="tty485", GROUP="dialout", MODE="0666"
KERNEL=="ttyUSB[0-9]*", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="tty232", GROUP="dialout", MODE="0666"
EOF
echo 'Adding udev rules done'

echo 'Changing php.ini'
post_max_size="= 256M"
for key in post_max_size
do
    sed -i "s/^\($key\).*/\1 $(eval echo \${$key})/" /etc/php5/apache2/php.ini
done
echo 'Changing php.ini done'


echo 'Installing unrar'
UNRAR_BUILD_DIR='/root/unrar'
apt-get remove unrar-free
mkdir ${UNRAR_BUILD_DIR}
cd ${UNRAR_BUILD_DIR}
apt-get build-dep unrar-nonfree
apt-get source -b unrar-nonfree
dpkg -i unrar*.deb
cd && rm -rf ${UNRAR_BUILD_DIR}
echo 'Installing unrar done'

echo 'Installing php-redis'
PHPREDIS_DIR="/root/src/phpredis"
git clone https://github.com/nicolasff/phpredis.git ${PHPREDIS_DIR}
cd ${PHPREDIS_DIR}
phpize
./configure
make && make install
echo 'extension=redis.so' > /etc/php5/apache2/conf.d/11-redis.ini
echo 'Installing php-redis done'

