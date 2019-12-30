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
apk add tmux emacs-nox htop curl wget wiringpi cage mesa-dri-vc4 libinput cmake make qt5-qtbase-dev qt5-qtwayland-dev git usb
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
apk add python3-dev py3-virtualenv
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
