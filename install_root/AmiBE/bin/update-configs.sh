#!/bin/bash

# set -x

#clear

my_name="${0##*/}"
my_path="${0%/${my_name}}"
. "${my_path}/config.sh"
. "${my_path}/mount-device-function.sh"

# NB This seems to be the only way to get Amiberry to observe a custom config dir
AMIBERRY_HOME_DIR="${base_path}"
AMIBERRY_CONFIG_DIR="${uae_config_path}"
export AMIBERRY_HOME_DIR
export AMIBERRY_CONFIG_DIR



update_config_file()
{
    # Fix paths
    grep -v "amiberry.rom_path=" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"
    grep -v "amiberry.floppy_path=" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"
    grep -v "amiberry.hardfile_path=" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"
    grep -v "amiberry.cd_path=" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"

    echo "amiberry.rom_path=${rom_path}/amiberry/" >> ${1}
    echo "amiberry.floppy_path=${adf_path}/" >> ${1}
    echo "amiberry.hardfile_path=${hdf_path}/" >> ${1}
    echo "amiberry.cd_path=${cdrom_path}/" >> ${1}

    # Look for markers in config description line
    ConfigLine=$(grep -i "config_description=" ${1})

    if [[ -n $ConfigLine ]]; then

        #GW=$(echo $ConfigLine | grep -Eo 'GW=[AB][0-3]')
        FDD=$(echo $ConfigLine | grep -Eo 'DF[0-3]=GW[AB]')
        HDD=$(echo $ConfigLine | grep -Eo 'HDD=''AUTO|DIR|NATIVE')

        # Backup the config file
        if [[ -n $FDD || -n $HDD ]]; then

            cp -f "${1}" "${1}.bak"

        fi

        if [[ -n $FDD ]]; then

            #GWCablePos=${GW:3:1}
            GWCablePos=${FDD:6:1}

            #GWAmigaDriveNo=${GW:4:1}
            GWAmigaDriveNo=${FDD:2:1}

            # Clear the floppybridge config lines
            grep -v "amiberry.drawbridge_" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"
            egrep -v "floppy${GWAmigaDriveNo}type" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"
            egrep -v "floppy${GWAmigaDriveNo}subtype" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"

            if [[ $(lsusb | grep -i "greaseweazle") ]]; then

                write_log "${1}: +DF${GWAmigaDriveNo} Greaseweazle pos ${GWCablePos}"

                # GGG Assume this is a Greaseweazle, 'cos that's all I have.
                echo "amiberry.drawbridge_driver=1" >> ${1}
                echo "amiberry.drawbridge_serial_autodetect=true" >> ${1}
                # echo "amiberry.drawbridge_serial_port=/dev/ttyACM0" >> ${1}
                echo "amiberry.drawbridge_serial_port=" >> ${1}
                echo "amiberry.drawbridge_smartspeed=false" >> ${1}
                echo "amiberry.drawbridge_autocache=false" >> ${1}

                if [[ ${GWCablePos} == 'B' ]]; then
                    echo "amiberry.drawbridge_connected_drive_b=true" >> ${1}
                    echo "amiberry.drawbridge_drive_cable=1" >> ${1}
                else
                    echo "amiberry.drawbridge_connected_drive_b=false" >> ${1}
                    echo "amiberry.drawbridge_drive_cable=0" >> ${1}
                fi

                echo "floppy${GWAmigaDriveNo}type=8" >> ${1}
                echo "floppy${GWAmigaDriveNo}subtype=1" >> ${1}
                echo "floppy${GWAmigaDriveNo}subtypeid=2:Compatible" >> ${1}

            elif [[ $GWAmigaDriveNo -gt 1 ]]; then

                # Virtual floppies 2 and 3 require type=0, so replace the line if we removed it
                echo "floppy${GWAmigaDriveNo}type=0" >> ${1}

            fi
        fi

        if [[ -n $HDD ]]; then

            HDD=${HDD#HDD=}

            if [[ $HDD == AUTO || $HDD == DIR ]]; then

                # Delete HDD folder lines from config
                grep -v "${volumes_path}/" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"

                # Append config for mounted devices
                cat ${var_path}/uae/hddir/*.uae >> ${1} 2>/dev/null

            fi

            if [[ $HDD == AUTO || $HDD == NATIVE ]]; then

                # Delete /dev lines from config
                grep -v "/dev/sd" ${1} > "${1}.temp" && mv -f "${1}.temp" "${1}"

                # Append config for unmounted block devices
                cat ${var_path}/uae/dev/*.uae >> ${1} 2>/dev/null

            fi
        fi
    fi
}


# Update config files
for file in "${uae_config_path}"/*.uae
do

    update_config_file $file $1

done


