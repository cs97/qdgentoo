#!/bin/sh

emerge --ask dev-lang/rust dev-vcs/git x11-terms/alacritty www-client/firefox

mkdir .config
mkdir .config/sway
mv .config/sway/config .config/sway/config.old

#sway status
git clone https://github.com/cs97/rusty-sway-status
cd rusty-sway-status
cargo build --release
cp target/release/status /usr/bin/status
cd ..

#sway .config
wget https://raw.githubusercontent.com/cs97/qdgentoo/master/conf/sway-config
mv sway-config .config/sway/config

#.bashrc
mv .bashrc .bashrc.old
wget https://raw.githubusercontent.com/cs97/qdgentoo/master/conf/.bashrc
