#!/usr/bin/env bash

#set -eu

## Enter the version to be used
XRDP_SOURCE=xrdp-0.9.12.tar.gz
XRDP_SOURCE_DIR="${XRDP_SOURCE%.tar.gz}"
XRDP_URL="https://github.com/neutrinolabs/xrdp/releases/download/v0.9.12/$XRDP_SOURCE"

## Enter the version to be used
XRDP_XORG_SOURCE=xorgxrdp-0.2.12.tar.gz
XRDP_XORG_SOURCE_DIR="${XRDP_XORG_SOURCE%.tar.gz}"
XRDP_XORG_URL="https://github.com/neutrinolabs/xorgxrdp/releases/download/v0.2.12/$XRDP_XORG_SOURCE"

sudo apt-get update
sudo apt-get install -y build-essential
sudo apt-get install -y git autoconf libtool pkg-config gcc g++ make  \
     libssl-dev libpam0g-dev libjpeg-dev libx11-dev libxfixes-dev \
     libxrandr-dev flex bison libxml2-dev intltool xsltproc xutils-dev \
     python-libxml2 g++ xutils libfuse-dev libmp3lame-dev nasm \
     libpixman-1-dev xserver-xorg-dev

# Download if not exist
if [ ! -f $XRDP_SOURCE ]; then
    echo "Downloading xrdp Source..."
    wget $XRDP_URL
fi

echo "STOPPING xrdp..."
#Xrdp-SesMan will be stopped
sudo systemctl daemon-reload
#Method here does not terminate sub-shell
STATUS="$(systemctl status xrdp 2>/dev/null | grep active)"
if [ "X${STATUS}" != "X"  ]; then
    sudo systemctl stop xrdp.service
    echo "xrdp STOPPED"
fi

## Always start from scratch !
if [ -d $XRDP_SOURCE_DIR ]; then
    echo "UNINSTALLING - Assume previous xrdp install..."
    cd $XRDP_SOURCE_DIR
    sudo make uninstall
    cd ..
    echo "REMOVING current xrdp build..."
    rm -rf $XRDP_SOURCE_DIR
fi
sudo systemctl daemon-reload

if [ ! -d $XRDP_SOURCE_DIR ]; then
        echo "UNPACKING xrdp..."
        tar xf $XRDP_SOURCE
fi

cd $XRDP_SOURCE_DIR
echo "CONFIGURING..."
# enable-strict-locations is necessary to get sysconfdir to change
# localstatedir must be /var, otherwise logs in wrong place.
    ./bootstrap
    ./configure \
            --with-systemdsystemunitdir=/etc/systemd/system \
            --enable-strict-locations \
 			--prefix=/usr/local \
 			--exec-prefix=/usr/local \
 			--bindir=/usr/local/bin \
 			--sbindir=/usr/local/sbin \
 			--includedir=/usr/local/include \
 			--mandir=/usr/local/share/man \
 			--infodir=/usr/local/share/info \
 			--sysconfdir=/usr/local/etc \
 			--libdir=/usr/local/lib \
 			--libexecdir=/usr/local/lib \
 			--localstatedir=/var

echo "BUILDING xrdp..."
make
echo "INSTALLING xrdp..."
sudo make install
cd ..

echo "XORG RDP"
# Download if not exist
if [ ! -f $XRDP_XORG_SOURCE ]; then
    echo "Downloading xorgxrdp Source..."
    wget $XRDP_XORG_URL
fi

## Always start from scratch !
if [ -d $XRDP_XORG_SOURCE_DIR ]; then
    cd $XRDP_XORG_SOURCE_DIR
    sudo make uninstall
    cd ..
    echo "Removing current xorgxrdp build..."
    rm -rf $XRDP_XORG_SOURCE_DIR
fi

if [ ! -d $XRDP_XORG_SOURCE_DIR ]; then
        echo "Unpacking xorgxrdp..."
        tar xf $XRDP_XORG_SOURCE
fi

cd  $XRDP_XORG_SOURCE_DIR
echo "CONFIGURING xrdp..."
./bootstrap
./configure
echo "BUILDING xrdp..."
make
echo "INSTALLING xrdp..."
sudo make install  
cd ..

echo "COPYING systemd FILES..."
sudo cp ./xrdp.service         /etc/systemd/system/
sudo cp ./xrdp-sesman.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable xrdp.service
sudo systemctl restart xrdp.service
sudo systemctl status xrdp.service

echo "DONE"
exit 0

