#!/bin/bash
# Run as root to update amiberry

# NB: This is a quickfix. Updates need more work.

my_name=${0##*/}
my_path=${0%/${my_name}}
. "${my_path}/config.sh"

unset arch

case $(uname -m) in
    "x86_64") arch=amd64 ;;
    "aarch64") arch=arm64 ;;
esac

if [[ ! -v arch ]]; then
    echo "This architecture is not supported."
    exit
fi

debian_version=$(cat /etc/debian_version)
major_version=${debian_version%%.*}

unset debian_codename

case $major_version in
    12) debian_codename=bookworm ;;
    13) debian_codename=trixie ;;
esac

if [[ ! -v debian_codename ]]; then
    echo "This OS is not supported."
    exit
fi


install_package ()
{
    echo "Installing ${1}.."
    write_log update "Installing package ${1}"

    if [[ $release ]]; then

        apt-get --assume-yes -qq install $1

    fi
}

install_amiberry_flavour ()
{
    # package_name must be amiberry or amiberry-lite
    package_name=${1:-"amiberry"}
    debfile=$(ls -vr ./${package_name}_*${arch}.deb | head -1)

    if [[ ! -f $debfile ]]; then

        zipfile=$(ls -vr ./${package_name}-v*${arch}.zip | head -1)

        if [[ ! -f $zipfile ]]; then

            wget_url=$(curl -s https://api.github.com/repos/BlitterStudio/${package_name}/releases/latest | grep browser_download_url.*debian-${debian_codename}-${arch} | cut -d : -f 2,3 | tr -d " \"")
            echo "Fetching ${package_name} installer from ${wget_url}"

            wget "${wget_url}"

            zipfile=$(ls -vr ./${package_name}-v*${arch}.zip | head -1)

        fi

        if [[ -f $zipfile ]]; then

            unzip -o $zipfile

        else

            echo "${package_name} download failed."

        fi

        debfile=$(ls -vr ./${package_name}_*${arch}.deb | head -1)

    fi

    if [[ -f $debfile ]]; then

        install_package "${debfile}"

    else

        echo "${package_name} installer not found! Please download and install manually."

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

mkdir /var/tmp/amibootenv 2>/dev/null
pushd /var/tmp/amibootenv

if [[ $(pwd) == /var/tmp/amibootenv ]]; then

    rm amiberry*.zip
    rm amiberry*.deb

    install_amiberry_flavour amiberry
    install_amiberry_flavour amiberry-lite

else

    echo "Sorry, something went wrong.."

fi

popd
