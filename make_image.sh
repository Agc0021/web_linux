#!/bin/bash
set -e
IMG="alpine-xfce-web.img"
MNT="/tmp/alpine-web"
ALPINE_VER="v3.20"
MIRROR="http://dl-cdn.alpinelinux.org/alpine"

# Clean up stale mounts
sudo umount "$MNT" 2>/dev/null || true

truncate -s 600M "$IMG"
mkfs.ext4 -F "$IMG"

sudo mkdir -p "$MNT"
sudo mount -o loop "$IMG" "$MNT"

# Copy host DNS settings so chroot has internet access
sudo cp /etc/resolv.conf "$MNT/etc/resolv.conf"

# Download static apk tool to bootstrap alpine
rm -f apk-tools-static-*.apk
wget -qO- "$MIRROR/$ALPINE_VER/main/x86/" | grep -o 'apk-tools-static-[^"]*\.apk' | head -n1 | xargs -I{} wget -q "$MIRROR/$ALPINE_VER/main/x86/{}"
tar -xzf apk-tools-static-*.apk -C /tmp sbin/apk.static

sudo /tmp/sbin/apk.static -X "$MIRROR/$ALPINE_VER/main" -X "$MIRROR/$ALPINE_VER/community" \
  -U --allow-untrusted --root "$MNT" --arch x86 --initdb add \
  alpine-base linux-virt syslinux openrc eudev

# Write repositories file inside chroot
sudo bash -c "cat << 'REPOS' > $MNT/etc/apk/repositories
$MIRROR/$ALPINE_VER/main
$MIRROR/$ALPINE_VER/community
REPOS"

# Install Xorg, drivers, and XFCE with internet working
sudo chroot "$MNT" /sbin/apk update
sudo chroot "$MNT" /sbin/apk add --no-cache \
  xorg-server xf86-video-vesa xf86-video-fbdev xf86-input-libinput \
  xfce4 xfce4-terminal dbus-x11 lightdm lightdm-gtk-greeter font-dejavu

sudo chroot "$MNT" rc-update add devfs sysinit
sudo chroot "$MNT" rc-update add udev sysinit
sudo chroot "$MNT" rc-update add networking boot
sudo chroot "$MNT" rc-update add dbus default
sudo chroot "$MNT" rc-update add lightdm default

echo "root:toor" | sudo chroot "$MNT" chpasswd

sudo extlinux --install "$MNT/boot"
sudo bash -c "cat << 'CONF' > $MNT/boot/extlinux.conf
DEFAULT alpine
LABEL alpine
  LINUX /boot/vmlinuz-virt
  INITRD /boot/initramfs-virt
  APPEND root=/dev/sda rw modules=sd-mod,usb-storage,ext4 quiet
CONF"

sudo umount "$MNT"
echo "Successfully generated $IMG"
