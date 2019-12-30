#!/bin/sh

set -xe

echo "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait" > /boot/cmdline.txt

cat <<EOF > /boot/config.txt
disable_splash=1
boot_delay=0
arm_64bit=1

# uart
enable_uart=1
dtoverlay=disable-bt

# display/camera
gpu_mem=128
dtoverlay=vc4-fkms-v3d
start_x=1

# monitor config
framebuffer_width=800
framebuffer_height=480
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt 800 480 60 6 0 0 0
EOF

# fstab
cat <<EOF > /etc/fstab
/dev/mmcblk0p1  /boot           vfat    defaults          0       2
/dev/mmcblk0p2  /               ext4    defaults,noatime  0       1
EOF
