#!/usr/bin/bash
sudo apt-get install -y gnome-common gtk-doc-tools libdconf-dev libnotify-dev valac

./autogen.sh

./configure --prefix=/usr --libexecdir=/usr/lib/ibus

make

sudo make install

ibus restart
