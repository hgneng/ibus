#!/bin/bash
sudo apt install -y gnome-common gtk-doc-tools libdconf-dev libnotify-dev valac libgtk-3-dev im-config
sudo apt install -y libspeechd-dev
sudo apt install -y ibus-pinyin
sudo apt install -y unicode unicode-data unicode-cldr-core
sudo apt install -y gconf2
sudo apt install -y libgirepository1.0-dev

./autogen.sh

sudo ln -s /usr/share/unicode /usr/share/unicode/ucd
./configure --prefix=/usr --libexecdir=/usr/lib/ibus --disable-gtk2

make

ps -ef | grep 'ibus-ui-gtk3' | grep -v grep | awk '{print $2}' | xargs kill

sudo make install

ui/gtk3/ibus-ui-gtk3&
#sleep 3
#sudo cp ui/gtk3/.libs/lt-ibus-ui-gtk3 /usr/lib/ibus/ibus-ui-gtk3

im-config -n ibus
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'pinyin')]"
ibus-daemon -drx
ibus restart
ibus engine pinyin
