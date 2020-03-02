#!/bin/sh

set -xe

TARGET_HOSTNAME="raspberrypi"

# base stuff
apk add ca-certificates
update-ca-certificates
echo "root:raspberry" | chpasswd
setup-hostname $TARGET_HOSTNAME
echo "127.0.0.1    $TARGET_HOSTNAME $TARGET_HOSTNAME.localdomain" > /etc/hosts
echo "::1          $TARGET_HOSTNAME $TARGET_HOSTNAME.localdomain" >>/etc/hosts
setup-keymap de de-dvorak

# time
apk add chrony tzdata
setup-timezone -z Europe/Berlin

# other stuff
apk add tmux emacs-nox htop curl wget wiringpi cage mesa-dri-vc4 libinput cmake make qt5-qtbase-dev qt5-qtwayland-dev git usbutils
echo "vc4" >/etc/modules-load.d/vc4.conf

# login
apk add util-linux
sed -E -e 's,getty(.*)$,agetty\1 linux,' -e '/tty1/s,agetty,agetty --autologin pi --noclear,' -i /etc/inittab

# octoprint
mkdir -p /usr/local/octoprint
addgroup -S octoprint
adduser -h /usr/local/octoprint -G octoprint -S -D octoprint
adduser octoprint dialout
chown octoprint:octoprint /usr/local/octoprint
apk add python3-dev py3-setuptools py3-virtualenv
su -s /bin/ash octoprint <<EOF
cd
virtualenv .
./bin/pip install octoprint
EOF
cat >/etc/init.d/octoprint <<EOF
#!/sbin/openrc-run
command="/usr/local/octoprint/bin/octoprint"
command_args="serve"
command_user="octoprint"
command_background="yes"
pidfile="/run/octoprint.pid"
depend() {
        need net
}
EOF
chmod +x /etc/init.d/octoprint
rc-update add octoprint

# mjpg-streamer
apk add ffmpeg libjpeg-turbo-dev runit
git clone https://github.com/raspberrypi/userland
cd userland
sed -i 's/ bash / sh /g' host_applications/linux/apps/raspicam/CMakeLists.txt
cmake . \
	-DCMAKE_C_FLAGS="$CFLAGS -D_GNU_SOURCE" \
	-DARM64=ON \
	-DCMAKE_BUILD_TYPE=MinSizeRel \
	-DCMAKE_INSTALL_RPATH=/opt/vc/lib \
	-DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-as-needed"
make install
cd ..
git clone https://github.com/jacksonliam/mjpg-streamer
cd mjpg-streamer/mjpg-streamer-experimental
cmake . \
	-DCMAKE_BUILD_TYPE=MinSizeRel \
	-DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-as-needed"
make install
cd ../..
rm -rf userland mjpg-streamer
addgroup -S mjpg
adduser -H -G mjpg -S -D mjpg
adduser mjpg video
cat >/usr/local/bin/mjpg.sh <<EOF
#!/bin/sh
set -e

modprobe bcm2835-v4l2
chgrp video /dev/video0
chmod g+rw /dev/video0

export LD_LIBRARY_PATH=/opt/vc/lib

v4l2-ctl --set-fmt-video=width=1440,height=1080,pixelformat=3
chpst -u mjpg:video -- mjpg_streamer -o "output_http.so -w /usr/local/share/mjpg-streamer/www/" -i "input_uvc.so -r 1440x1080 -d /dev/video0 -f 15"
EOF
cat >/etc/init.d/mjpg-streamer <<EOF
#!/sbin/openrc-run
command="/usr/local/bin/mjpg.sh"
command_background="yes"
pidfile="/run/mjpg-streamer.pid"
depend() {
        need net
}
EOF
chmod +x /usr/local/bin/mjpg.sh /etc/init.d/mjpg-streamer
rc-update add mjpg-streamer
