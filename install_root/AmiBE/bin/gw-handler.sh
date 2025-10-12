#!/bin/bash

# Process running check, only works without SUDO. ($$ = PID of this instance)
if [[ $(pgrep -f $0) != $$ ]]; then

    echo "${0}: Another instance is already running."
    exit

fi

my_name="${0##*/}"
my_path="${0%/${my_name}}"
. "${my_path}/config.sh"


while [[ 1 ]]; do

    event=$(inotifywait -q -e CREATE,DELETE "/dev/" --includei "ttyACM[0-9]$")

    write_log "${my_name} event ${event}"

    sleep 1

    . "${my_path}/update-configs.sh"

done

