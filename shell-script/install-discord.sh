#! /bin/bash

#echo "net-im/discord-bin all-rights-reserved" > /etc/portage/package.license/discord

#echo "net-im/discord-bin ~amd64" > /etc/portage/package.accept_keywords/discord

#echo "app-text/ghostscript-gpl cups" > /etc/portage/package.use/discord

echo "net-im/discord all-rights-reserved" > /etc/portage/package.license/discord

#emerge --ask net-im/discord-bin media-libs/libpulse

emerge --ask --verbose net-im/discord
