#! /bin/bash

echo "net-im/discord-bin all-rights-reserved" > /etc/portage/package.license/discord

echo "net-im/discord-bin ~amd64" > /etc/portage/package.accept_keywords/discord

echo "app-text/ghostscript-gpl cups" > /etc/portage/package.use/discord

emerge --ask net-im/discord-bin
