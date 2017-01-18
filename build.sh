#!/bin/bash
set -e

function set_static_ip() {
    echo "Configuring static IP address..."
    DHCPCD_CONF="/etc/dhcpcd.conf"
    CURRENT_CONF=`cat ${DHCPCD_CONF}`
    cat << EOF > ${DHCPCD_CONF}
interface eth0
 static ip_address=$1/24
 static routers=192.168.1.1
 static domain_name_servers=8.8.8.8

$CURRENT_CONF
EOF
    systemctl daemon-reload
    systemctl restart networking
    sleep 2
    echo "IP static done."
}

function add_user {
    echo "Adding user $1"
    password=$2 # your chosen password
    enc_pass=$(perl -e 'printf("%s\n", crypt($ARGV[0], "password"))' "$password")
    useradd -m -p ${enc_pass} $1
    usermod -a -G video $1
    usermod -a -G gpio $1
    echo "$1 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/020_user-sudo
    echo "Adding user done"
}

function set_autologin_for {
    echo "Setting autologin for $1"
    DEFAULT_USER=latinus
    perl -pi -e "s/--autologin $DEFAULT_USER/--autologin $1/g" /etc/systemd/system/getty.target.wants/getty@tty1.service
    echo "Setting autologin for $1 done"
}

function apt_add_sources {
    # Un-comment deb-src and update
    sed -i '/deb-src/s/^#//g'  /etc/apt/sources.list
}

function install_base_deps {
    DEPS="xorg dbus-x11 xapache2 libapache2-mod-php5 xinit  python-gtk2 python-pip git python-imaging python-dbus redis-server php5-dev sudo python-dev x11-xserver-utils"
    PIP_INSTAL="toml redis pyserial wiringpi2 sysfs"
    apt-get install -y ${DEPS}
    pip install ${PIP_INSTAL}
}

function configure_apache {
    a2enmod rewrite
    sed -i "s/www-data/latinus/g" /etc/apache2/envvars
    sed -i "s/DocumentRoot \/var\/www\/html/DocumentRoot \/home\/latinus\/public_html/g" /etc/apache2/sites-enabled/000-default.conf
    service apache2 restart
}

function add_udev_rules {
    echo 'Adding udev rules'
    UDEV_CONF="/etc/udev/rules.d/80-my-device.rules"
    cat << EOF > ${UDEV_CONF}
KERNEL=="ttyUSB[0-9]*", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="tty485", GROUP="dialout", MODE="0666"
KERNEL=="ttyUSB[0-9]*", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="tty232", GROUP="dialout", MODE="0666"
EOF
    echo 'Adding udev rules done'
}

function configure_php {
    echo 'Changing php.ini'
    short_open_tag = "=On"
    post_max_size = "=256M"
    error_reporting = "=E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE"
    for key in post_max_size error_reporting short_open_tag
    do
        sed -i "s/^\($key\).*/\1 $(eval echo \${$key})/" /etc/php5/apache2/php.ini
    done
    echo 'Changing php.ini done'
}

function install_unrar {
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
}

function install_phpredis {
    echo 'Installing php-redis'
    PHPREDIS_DIR="/root/src/phpredis"
    git clone https://github.com/nicolasff/phpredis.git ${PHPREDIS_DIR}
    cd ${PHPREDIS_DIR}
    phpize
    ./configure
    make && make install
    echo 'extension=redis.so' > /etc/php5/apache2/conf.d/11-redis.ini
    cd && rm -rf ${PHPREDIS_DIR}
    echo 'Installing php-redis done'
}

function install_qt_deps {
    # From https://wiki.qt.io/RaspberryPi2EGLFS
    QT_DEPS="libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0"
    PREFIX_TARGET=/usr/local/qt5pi # same as in .envrc
    apt-get build-dep -y qt4-x11
    apt-get build-dep -y libqt5gui5
    apt-get install -y ${QT_DEPS} 
    mkdir ${PREFIX_TARGET}
    chown pi:pi ${PREFIX_TARGET}
    echo ${PREFIX_TARGET}/lib | tee /etc/ld.so.conf.d/qt5pi.conf
    ldconfig
    rm /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0 /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0
    ln -s /opt/vc/lib/libEGL.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0
    ln -s /opt/vc/lib/libGLESv2.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0
    ln -s /opt/vc/lib/libEGL.so /opt/vc/lib/libEGL.so.1
    ln -s /opt/vc/lib/libGLESv2.so /opt/vc/lib/libGLESv2.so.2
}

function add_private_key {
    echo "Adding private key"
    SSH_DIR="/root/.ssh/"
    PRIVATE_KEY="${SSH_DIR}/id_rsa"
    mkdir -p $SSH_DIR
    cat << EOF >> ${PRIVATE_KEY}
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAvDNt5ZAFdOY7H+rkSwRiCdg6xrLsaGzRarY8D9I3zacJAV/n
7UWcOHCso41lZCDxq5fkp40O1XsC0X4vUWesx/8cZk5uAGotgrnsFKi3viTYmaFV
sM337PA+c0Qn8Q/QS3//aDtXFzwrZjDvPND+nsUanSSVB79yiMTpXLsGU9P1ZM5v
4Sc/NUNAQ/MMB5tKMACqoKuWOR1bhZI22WS7LR2UbzqCLIDM47fXzPQEc3yOvECW
FQZPQnggYUIyKic7lGfpIJ8ES5jdXtj2PkXdoTSwMyEtJPl0CSvNHht+bkRmPjzH
CmPZNnRGnUdyUoHdlXYR2arqdXasvdZ3YKoZtQIDAQABAoIBAQCGztAJgABonAH9
+uNMWPdg1eJEMiXlJw1awu6C5rHSPbPVqD0ZWKNuSkdfYAkgj/iMUWEYI5JcmKCM
Lzb1uK2rFLHjFor1ARlYapUQt0nmib4dTdNzshXFQtF4/3kc05cAfc8VemwH2LG9
oY+8oHfCgq1toqadxiTkkygVpGID6LUXT4kAM6QEyzbkiXWrqezoYNC2aO0mzcdU
UCRmANEv/+XVGVzllO31/Ddd8ex8B9BtPrPwJwDyGbRE1tEPhfKwImfpJSIIRDqm
iZTCtdxCeJZdBfFpZlNU8LI4l2Go5nOeq/bwW465YX9SleSmOO+l7PTTLbBDPxWa
YpipXlwBAoGBAOeAWwSDgRs3GxGzM/VqmLdbIG8LflhuekB/3e/CQy9JxbeoU4ID
REvarBbxrVhHw+6b8gEyKw4X5Drfglv2i1xSSDi9LFGNlgaH7RLUktcPeptQpg0d
gHCr5iODci+4cnq4Rl60g7eAmoz7ezYmRHhVYLp+OqsYCZ0UXyq2rEI9AoGBANAe
AzXhl/uMeHpjuNZ0WjdKawClyhpH9b6F1oVEpgtcLrwHpfyAkQhkbnNoZozbr9UP
pXqhGGmwc+1eFvhewsZbqT4y3UKi7bVGlQKVF+VHzBhByADiLGxEpRQAhTdTLhP7
DuUgjOW9nWLLCjt+9/9YW7IZdil1mUAJI0Ig4QTZAoGBAJ0YbCtm9eC7B2J+gh7j
RFkAvMS+PvHRnqJQYxIFeMQJQuO7lVef0ePLs4YqYKCMqrgsGRCYs8Dvk5AkBnlT
mASBTcM7FG0PMKSj7swddrv8JA5rrxMtVvCepiCpXX5mo0EF9bLkupF28uoC6fy4
ATTLc0V6zWM3f6aZoW8B4WldAoGBAIOw2hs4OzHDu2DGxWl+iq+9+WOZhP+IVWpP
ymTeAavikvgMZu4WdK+4zWNdxraPNP4/PlkQoyANte2XwjU70UgvLDLdgMDv1DcH
CLdvnIVLH0yiI2rbs3x3G3ZCtglCK0Add1lpdX7Ss0qWbE0llMwRH0Tdc7XcYjLx
FUx8/aZRAoGAeXXqORxtJNQWeiFZId2lxgCUKjx1shHSDcmnahkmZskSy61RB+AV
akPhCDSTuvThUbndvqez4261xiQwDQWXTJ3WeIqAvMGd4+9GUnS3qj7iZaruyVkf
/eiP93YGT9M6n6QEiAmwr3bAShz4qIHGKM4gnJNM5dSelfkkIWpafKY=
-----END RSA PRIVATE KEY-----
EOF
    chmod 400 ${PRIVATE_KEY}
    ssh-keyscan gitlab.com >> "${SSH_DIR}/known_hosts"
    echo "Adding private key done"
}

function git_clone_source {
    echo "Cloning source"
    cd /home/latinus/
    git init
    git remote add origin git@gitlab.com:hadi60/latinus.git
    git fetch --all
    git reset --hard origin/master
    chown -R latinus:latinus /home/latinus
    echo "Cloning source done"
}

USER=latinus
PASSWORD=freelatinus

# set_static_ip 192.168.1.89
# add_user $USER $PASSWORD
# set_autologin_for $USER
# apt_add_sources
# apt-get update
# install_base_deps
# configure_apache
# configure_php
# install_unrar
# add_udev_rules
# install_phpredis
# install_qt_deps
add_private_key
git_clone_source

