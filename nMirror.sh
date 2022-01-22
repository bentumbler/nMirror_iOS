#!/bin/bash

echo "installing dependencies"

read -p "Do you want to update/install build tools (you need to if this is a new image) (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo apt-get -q update
    sudo apt-get -q install \
                    build-essential \
                    checkinstall \
                    git \
                    autoconf \
                    automake \
                    libtool-bin
fi


echo "installing libatomic"
sudo apt-get -q install libatomic-ops-dev libatomic1


echo "installing libimobiledevice dependencies"
sudo apt-get -q install \
                libplist-dev \
                libusbmuxd-dev \
                libimobiledevice-glue-dev \
                libimobiledevice-dev \
                libusb-1.0-0-dev \
                libplist++-dev \
                libssl-dev \
                usbmuxd \
                udev \
                libavahi-client-dev \
                avahi-utils 

echo "installing pythin bindings"
sudo apt-get install \
	doxygen \
	cython

echo "Starting nMirror setup"

# Configure source directories
nMirrorDir=~/nMirror

echo "The applications needed for nMirror will be installed in $nMirror"

libplistDir=$nMirrorDir/libplist
libusbmuxdDir=$nMirrorDir/libusbmuxd
libimobiledeviceDir=$nMirrorDir/libimobiledevice
libgeneralDir=$nMirrorDir/libgeneral
usbmuxd2Dir=$nMirrorDir/usbmuxd2

#Standard libimobiledevice repos
libplistGit=https://github.com/libimobiledevice/libplist.git
libusbmuxdGit=https://github.com/libimobiledevice/libusbmuxd.git
libimobiledeviceGit=https://github.com/libimobiledevice/libimobiledevice.git

#tihmstar repo for usbmuxd2 to support network connection to iDevice
usbmuxd2Git=https://github.com/tihmstar/usbmuxd2.git
libgeneralGit=https://github.com/tihmstar/libgeneral.git



# Create the project directory if it does not exist
mkdir -p $nMirrorDir
cd $nMirrorDir


# Fetch the repos

fetchnext=false
if test -d $libplistDir; then
    read -p "libplist directory exists. Remove and re-fetch new? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        rm -rf $libplistDir
        fetchnext=true
    fi
else
    fetchnext=true
fi
if [ "$fetchnext" == true ]; then
    echo "Cloning from git.  1 - libplist"
    cd $nMirrorDir
    git clone --quiet $libplistGit
    cd $libplistDir
    # git checkout 2.2.0 # Cannot go back to the last tag (2.2.0) because usbmuxd2 want 2.2.1 - just get the head for now
fi


if test -d $libusbmuxdDir; then
    read -p "libusbmuxd directory exists. Remove and re-fetch new? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        rm -rf $libusbmuxdDir
        fetchnext=true
    fi
else
    fetchnext=true
fi
if [ "$fetchnext" == true ]; then
    echo "Cloning from git.  2 - libusbmuxd (Normal)"
    cd $nMirrorDir
    git clone --quiet $libusbmuxdGit
    cd $libusbmuxdDir
    git checkout 2.0.2
fi

if test -d $libimobiledeviceDir; then
    read -p "libimobiledevice directory exists. Remove and re-fetch new? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        rm -rf $libimobiledeviceDir
        fetchnext=true
    fi
else
    fetchnext=true
fi
if [ "$fetchnext" == true ]; then
    echo "Cloning from git.  3 - libimobiledevice"
    cd $nMirrorDir
    git clone --quiet $libimobiledeviceGit
    cd $libimobiledeviceDir
    # git checkout 1.3.0
    # going to head of master to get 1.3.1
fi


#tihmstar repo for usbmuxd2 to support network connection to iDevice
if test -d $libgeneralDir; then
    read -p "libgeneral directory exists. Remove and re-fetch new? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        rm -rf $libgeneralDir
        fetchnext=true
    fi
else
    fetchnext=true
fi
if [ "$fetchnext" == true ]; then
    echo "Cloning from git.  4 - libgeneral (tihmstar Experimental repo tag 55)"
    cd $nMirrorDir
    git clone --quiet $libgeneralGit
    cd $libgeneralDir
    git checkout 55
fi


if test -d $usbmuxd2Dir; then
    read -p "usbmuxd2 directory exists. Remove and re-fetch new? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        rm -rf $usbmuxd2Dir
        fetchnext=true
    fi
else
    fetchnext=true
fi
if [ "$fetchnext" == true ]; then
    echo "Cloning from git.  5 - usbmuxd2 (tihmstar Eperimental repo)"
    cd $nMirrorDir
    git clone --quiet $usbmuxd2Git
    cd $usbmuxd2Dir
    git submodule init
    git submodule update
fi

#build stage

cd $libplistDir
./autogen.sh
make
sudo make install

cd $libusbmuxdDir
./autogen.sh
make
sudo make install

cd $libimobiledeviceDir
./autogen.sh
make
sudo make install

sudo ldconfig

#configure Avahi for zeroconf as per https://www.raspberrypi.org/forums/viewtopic.php?t=267113
#Note: Zeroconf may not be desirable - use with caution
cd $nMirrorDir

#create avahi patch
tee avahi.patch <<EOF
--- /etc/avahi/avahi-daemon.conf 2021-08-16 23:59:16.917672251 +0100
+++ /etc/avahi/avahi-daemon_usbmuxd.conf 2021-08-17 09:45:02.096575347 +0100
@@ -20,7 +20,7 @@
 
 [server]
 #host-name=foo
-#domain-name=local
+domain-name=local
 #browse-domains=0pointer.de, zeroconf.org
 use-ipv4=yes
 use-ipv6=yes
@@ -46,8 +46,8 @@
 #disable-user-service-publishing=no
 #add-service-cookie=no
 #publish-addresses=yes
-publish-hinfo=no
-publish-workstation=no
+publish-hinfo=yes
+publish-workstation=yes
 #publish-domain=yes
 #publish-dns-servers=192.168.50.1, 192.168.50.2
 #publish-resolv-conf-dns-servers=yes
EOF

cd /etc
sudo patch -p2 < $nMirrorDir/avahi.patch

#enable the avahi-daemon
systemctl list-unit-files avahi-daemon.service
#activate/enable the avahi-daemon.service
sudo systemctl enable avahi-daemon.service
sudo systemctl start avahi-daemon.service
sudo systemctl restart avahi-daemon.service
#enable ssh service
sudo systemctl enable ssh.service
sudo systemctl start ssh.service
#avahi-browse -a 


# if using gcc: the patch below works to include -latomic 
# if using clang: make CXX=clang++

cd $libgeneralDir
./autogen.sh
make CFLAGS="-g -O2 -std=c11 -latomic" LDFLAGS=-latomic
sudo make install

sudo ldconfig

cd $usbmuxd2Dir

#create log patch
#cassure only needed for versions after 55 - probably remove this as checkout is fixed to 55
tee log.patch <<EOF
--- a/configure.ac
+++ b/configure.ac
@@ -29,7 +29,7 @@ case $host_os in
         have_mdns="yes"
         ;;
   *)
-        LDFLAGS+=" -lstdc++fs"
+        LDFLAGS+="-latomic -lstdc++fs"
         ;;
 esac
 

EOF

git apply log.patch
./autogen.sh
make
sudo make install

sudo ldconfig


# get the BT PAN up and running
sudo apt-get install bluez-tools

sudo tee /etc/systemd/network/pan0.netdev <<EOF
[NetDev]
Name=pan0
Kind=bridge
EOF
 
 
sudo tee /etc/systemd/network/pan0.network <<EOF
[Match]
Name=pan0

[Network]
Address=172.20.1.1/24
DHCPServer=yes
EOF
 
sudo tee /etc/systemd/system/bt-agent.service <<EOF
[Unit]
Description=Bluetooth Auth Agent
 
[Service]
#ExecStart=/usr/bin/bt-agent -c NoInputNoOutput
ExecStart=/bin/sh -c '/usr/bin/yes | /usr/bin/bt-agent --capability=NoInputNoOutput' #autoaccept
Type=simple
 
[Install]
WantedBy=multi-user.target
EOF
 
sudo tee /etc/systemd/system/bt-network.service <<EOF
[Unit]
Description=Bluetooth NEP PAN
After=pan0.network

[Service]
ExecStart=/usr/bin/bt-network -s nap pan0
Type=simple

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable systemd-networkd
sudo systemctl enable bt-agent
sudo systemctl enable bt-network
sudo systemctl start systemd-networkd
sudo systemctl start bt-agent
sudo systemctl start bt-network

sudo bt-adapter --set Discoverable 1

# list devices. Need to ask the user to connect via USB the first time using idevicesyslog. Then make the BT PAN connection and connect via idevicesyslog -n

/usr/local/bin/idevice_id 
