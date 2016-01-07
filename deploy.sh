#!/bin/bash
sudo apt-get install -y gnome-common gtk-doc-tools libdconf-dev libnotify-dev valac libgtk-3-dev im-config
sudo apt-get install -y libspeechd-dev
sudo apt-get install -y ibus-pinyin

./autogen.sh

./configure --prefix=/usr --libexecdir=/usr/lib/ibus --disable-gtk2

make

ps -ef | grep 'ibus-ui-gtk3' | grep -v grep | awk '{print $2}' | xargs kill

sudo make install

ui/gtk3/ibus-ui-gtk3&
sleep 3
sudo cp ui/gtk3/.libs/lt-ibus-ui-gtk3 /usr/lib/ibus/ibus-ui-gtk3

im-config -n ibus
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'pinyin')]"
ibus-daemon -drx
ibus restart
