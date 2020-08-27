#!/bin/bash

# test for root and exit
[ "$EUID" -ne 0 ] && echo "Please run as root" && exit
echo "User is root - proceeding..."

# Test for and install/update docker-compose
composeVer=$(curl -fsSLI -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest | sed 's#.*tag/##g')
if [ ! -x "$(command -v docker-compose)" ] || [ $(docker-compose version --short) != $composeVer ]; then
    curl -L "https://github.com/docker/compose/releases/download/$composeVer/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose
fi