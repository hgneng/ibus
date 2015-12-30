#!/usr/bin/bash
sudo apt-get install -y gnome-common gtk-doc-tools libdconf-dev libnotify-dev valac
sudo apt-get install -y libspeechd-dev
sudo apt-get install -y ibus-pinyin

./autogen.sh

./configure --prefix=/usr --libexecdir=/usr/lib/ibus

make

sudo make install

im-switch -s ibus
ibus restart
