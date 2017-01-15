#!/bin/bash
# From https://wiki.qt.io/RaspberryPi2EGLFS
QT_DEPS="libudev-dev libinput-dev libts-dev libxcb-xinerama0-dev libxcb-xinerama0"
PREFIX_TARGET=/usr/local/qt5pi # same as in .envrc
apt-get build-dep qt4-x11
apt-get build-dep libqt5gui5
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
