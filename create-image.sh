#!/bin/bash

# Script to build openwrt image based on http://hackstack.org/x/blog/2014/08/17/openwrt-images-for-openstack/


git clone git://git.openwrt.org/openwrt.git

cd openwrt

echo "src-git dtroyer https://github.com/dtroyer/openwrt-packages" >>feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a

make defconfig

make menuconfig

make -j 8


gzip -dc bin/x86/openwrt-x86-kvm_guest-combined-ext4.img.gz > ../openwrt-x86-kvm_guest-combined-ext4.img
cd ..

sudo kpartx -av openwrt-x86-kvm_guest-combined-ext4.img

mkdir -p imgroot

sudo mount -o loop /dev/mapper/loop0p2 imgroot

sudo chroot imgroot /bin/ash

sed -e '/^root/ s|^root.*$|root:\!:16270:0:99999:7:::|' -i /etc/shadow

# Temporary fix for bug https://github.com/dtroyer/openwrt-packages/issues/1
sed -i 's|/root/.ssh/authorized_keys|/etc/dropbear/authorized_keys|g' /etc/init.d/rc.cloud-setup

uci set dropbear.@dropbear[0].PasswordAuth=off
uci commit dropbear

uci set network.lan.proto=dhcp;
uci commit

# This one doesnt make sense 
# sed -e "s|http.*/x86/|http://bogus.hackstack.org/openwrt/x86/|" -i /etc/opkg.conf

sudo umount imgroot
sudo kpartx -av openwrt-x86-kvm_guest-combined-ext4.img

# Upload to openstack
# openstack image create --file openwrt-x86-kvm_guest-combined-ext4.img --property os-distro=OpenWRT OpenWRT
