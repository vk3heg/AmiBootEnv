#!/bin/bash

# Process running check, only works without SUDO. ($$ = PID of this instance)
if [[ $(pgrep -f $0) != $$ ]]; then

    echo "${0}: Another instance is already running."
    exit

fi

my_name="${0##*/}"
my_path="${0%/${my_name}}"
. "${my_path}/config.sh"


process_event()
{
    write_log "${my_name} event ${2} ${3}"

    case "$2" in

        CREATE)

            sleep 1
            for dev in $(ls "/dev/${3}p"?); do   # GGG this ls syntax is not working?

                /bin/bash "${my_path}/mount-device.sh" "${dev}" &

            done

        ;;

        DELETE)

            for path in $(grep -E "^/dev/${3}p[1-9] " /proc/mounts | cut -d ' ' -f 2); do

                /bin/bash "${my_path}/unmount-path.sh" "${path}" &

            done

        ;;

    esac
}


while [[ 1 ]]; do

    process_event $(inotifywait -q -e CREATE,DELETE "/dev/" --includei "mmcblk[0-9]$")

    . "${my_path}/update-configs.sh"

done
