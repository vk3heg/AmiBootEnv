#!/bin/bash
# Run as root to update amiberry

my_name=${0##*/}
my_path=${0%/${my_name}}
. "${my_path}/config.sh"

case $(uname -m) in
    x86_64)
    arch=amd64
    ;;

    aarch64)
    arch=arm64
    ;;

    *)
    echo "This architecture is not supported."
    exit
    ;;
esac

debian_version=$(cat /etc/debian_version)
major_version=${debian_version%%.*}

case $major_version in
    12)
    debian_codename=bookworm
    ;;

    13)
    debian_codename=trixie
    ;;

    *)
    echo "This OS version is not supported."
    exit
    ;;
esac


install_package ()
{
    echo "Installing ${1}.."
    write_log update "Installing package ${1}"

    if [[ $release ]]; then

        apt-get --assume-yes -qq install $1

    fi
}

echo "This script will download and install the latest Amiberry release."
echo -n "Do you wish to proceed? (Y/N) : "

read answer

if [[ $answer != "y" && $answer != "Y" ]]; then

    exit

fi


apt update
apt install curl

rm amiberry*.zip

# pushd "/var/tmp"

wget_url=$(curl -s https://api.github.com/repos/BlitterStudio/Amiberry/releases/latest | grep browser_download_url.*debian-${debian_codename}-${arch} | cut -d : -f 2,3 | tr -d " \"")
echo "Fetching Amiberry installer from ${wget_url}"
write_log update "Fetching Amiberry installer from ${wget_url}"

wget "${wget_url}"

amiberry_zipfile=$(ls -vr ./amiberry*${arch}.zip | head -1)

if [[ -f $amiberry_zipfile ]]; then

	# Sleep to prevent occasional unzip failure
	sleep 1
    unzip -o ./amiberry*${arch}.zip

else

    write_log update "Amiberry installer archive not found!"
    write_log update "URL = ${wget_url}"
    echo "Amiberry download failed."

fi

amiberry_installer=$(ls -vr ./amiberry*${arch}.deb | head -1)

if [[ -f $amiberry_installer ]]; then

    install_package $amiberry_installer

else

    write_log update "Amiberry installer not found! Please download and install manually."
    echo "Amiberry installer not found! Please download and install manually."

fi

# pushd -1



