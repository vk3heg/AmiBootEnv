#!/bin/bash
clear

my_name="${0##*/}"
my_path="${0%/${my_name}}"
. "${my_path}/config.sh"

if [[ $abe_use_xorg ]]; then

    startx

else

    /AmiBE/bin/main.sh

fi


