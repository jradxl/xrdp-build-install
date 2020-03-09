#!/usr/bin/env bash

set -eu

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
#xrdp-sesman will be stopped
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
# localstatedir must be /run, and log location is set in *.ini files.
    ./bootstrap
    ./configure \
            --with-systemdsystemunitdir=./systemd-ref \
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
 			--localstatedir=/run/xrdp \
 			--with-socketdir=/run/xrdp/sockdir \
			--disable-maintainer-mode \
			--disable-dependency-tracking \
			--disable-silent-rules 

echo "BUILDING xrdp..."
echo "Applying Patch xrdp..."
patch -u ./common/os_calls.c -i ../fix_perms.patch
patch -u ./libtool -i ../libtool.patch
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
#Non Forking 
#sudo cp ./xrdp.service-nodaemon         /etc/systemd/system/xrdp.service
#sudo cp ./xrdp-sesman.service-nodaemon  /etc/systemd/system/xrdp-sesman.service

#Or Forking
sudo cp ./xrdp.service-forking         /etc/systemd/system/xrdp.service
sudo cp ./xrdp-sesman.service-forking  /etc/systemd/system/xrdp-sesman.service

sudo cp ./xrdp-sesman-pamd     /etc/pam.d/xrdp-sesman
sudo cp ./sesman.ini           /usr/local/etc/xrdp/
sudo cp ./xrdp.ini             /usr/local/etc/xrdp/
sudo cp ./prepare-environment  /usr/local/etc/xrdp/
sudo cp ./envvars              /usr/local/etc/xrdp/

#Created automatically
#sudo cp ./xorg.conf            /etc/X11/xrdp/xorg.conf

# Generate RDP security keys
if [ ! -f /usr/local/etc/xrdp/rsakeys.ini ]; then
    echo "Creating xRDP security key"
	umask 077
	xrdp-keygen xrdp auto
fi
sudo chown xrdp /usr/local/etc/xrdp/rsakeys.ini

# Generate/copy snakeoil X509 certificate and key
if [ ! -f  /usr/local/etc/xrdp/cert.pem ]; then
    echo "Creating snakeoil certificate key"
    if [ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]; then
	    make-ssl-cert generate-default-snakeoil
	fi
	#Linking does not work!
	cp /etc/ssl/certs/ssl-cert-snakeoil.pem   /usr/local/etc/xrdp/cert.pem
	cp /etc/ssl/private/ssl-cert-snakeoil.key /usr/local/etc/xrdp/key.pem
fi
chown xrdp:xrdp /usr/local/etc/xrdp/cert.pem
chown xrdp:xrdp /usr/local/etc/xrdp/key.pem

#Must be run prior to running xrdp on command-line or
#and is run by systemctl start xrdp
sudo ./prepare-environment

sudo systemctl daemon-reload

#sudo systemctl enable xrdp.service
#sudo systemctl restart xrdp.service
#sudo systemctl status xrdp.service

echo "DONE"
exit 0

