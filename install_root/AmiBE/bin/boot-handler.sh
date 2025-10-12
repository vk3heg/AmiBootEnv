#!/bin/bash

kernel_boot_options="ro quiet splash"

# Uncomment for systems throwing ACPI errors
#kernel_boot_options="${kernel_boot_options} libata.noacpi=1"


# Process running check, only works without SUDO. ($$ = PID of this instance)
if [[ $(pgrep -f $0) != $$ ]]; then

    echo "${0}: Another instance is already running."
    exit

fi

my_name="${0##*/}"
my_path="${0%/${my_name}}"
. "${my_path}/config.sh"

mkdir -p "${var_path}" 2>/dev/null
boot_stanzas_file="${var_path}/boot.conf"


update_boot_stanzas () {

    lsblk_output=$(lsblk -r -o MOUNTPOINT,PARTUUID,UUID | grep "^/ ")
    uuids=${lsblk_output#* }
    partition_uuid=${uuids% *}
    filesystem_uuid=${uuids#* }
    kernel_file=$(ls -vr /boot/${kernel_prefix}* | head -1)
    initrd_file=$(ls -vr /boot/${initrd_prefix}* | head -1)

    if [[ -f "${boot_stanzas_file}" ]]; then

        rm "${boot_stanzas_file}"

    fi

    for file in "${uae_config_path}"/*.uae
    do

        description_line=$(grep --no-filename "config_description=" "${file}")

        if [[ -n $description_line ]]; then

            boot_icon=$(echo $description_line | egrep -o "BOOTICON=.*\.png")

            if [[ -n $boot_icon ]]; then

                icon=${boot_icon#BOOTICON=}
                shortname=${file##*/}
                shortname=${shortname%.uae}

                # echo "Adding boot entry \"${shortname}\""
                #write_log "Updating boot stanza : ${shortname} icon=${icon} volume=${partition_uuid} loader=${kernel_file} initrd=${initrd_file} UUID=${filesystem_uuid} ${kernel_boot_options}"

                # NB icon must be the first line of the stanza!
                echo "" >> "${boot_stanzas_file}"
                echo "menuentry \"${shortname}\" {" >> "${boot_stanzas_file}"
                echo " icon EFI/refind/amiboot/icons/${icon}" >> "${boot_stanzas_file}"
                echo " ostype linux" >> "${boot_stanzas_file}"
                echo " volume ${partition_uuid}" >> "${boot_stanzas_file}"
                echo " loader ${kernel_file}" >> "${boot_stanzas_file}"
                echo " initrd ${initrd_file}" >> "${boot_stanzas_file}"
                echo " options \"root=UUID=${filesystem_uuid} ${kernel_boot_options}\"" >> "${boot_stanzas_file}"
                echo "}" >> "${boot_stanzas_file}"

            fi

        fi

    done

    if [[ $release && -d "${efi_path}/refind/amiboot/" ]]; then

        cp -f "${boot_stanzas_file}" "${efi_path}/refind/amiboot/"

    fi

}


if [[ -d "${efi_path}/refind/amiboot/" ]]; then

    if [[ $1 == "watch" ]]; then

        while [[ 1 ]]; do

            event=$(inotifywait -q -e modify,create,delete,move "${uae_config_path}")

            write_log "${my_name} event ${event}"

            # Wait for config file refresh to complete
            sleep 3

            update_boot_stanzas

        done

    else

        update_boot_stanzas

    fi

fi

