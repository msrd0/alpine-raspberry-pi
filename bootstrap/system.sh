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
apk add emacs-nox htop curl wget wiringpi cage cmake make qt5-qtbase-dev qt5-qtwayland-dev git

# octoprint
mkdir -p /usr/local/octoprint
adduser -h /usr/local/octoprint -G dialout -S -D octoprint octoprint
chown octoprint:octoprint /usr/local/octoprint
su octoprint <<EOF
virtualenv .
./bin/pip install octoprint
EOF
