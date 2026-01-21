AmiBootEnv Non-Root Installation - Development Log
Overview

This document describes modifications made to AmiBootEnv to support running as a non-root user after installation. The original Install.sh runs Amiberry as root; the modified Install-nonroot.sh creates a dedicated amiberry user and runs the emulator with reduced privileges.
Issues Identified
Issue 1: Exit Menu Options Not Working

Affected Options: "Edit AmiBootEnv Options" and "Terminal"

Symptoms:

    Selecting "Terminal" restarted Amiberry instead of dropping to a shell
    Selecting "Edit Options" restarted Amiberry instead of opening the editor

Root Cause:

The original main.sh uses a single while loop structure:

while [[ 1 ]]; do
    launch_amiberry
    # ... build menu ...
    . abe-menu.sh

    if [[ "$selection" == "Terminal" ]]; then
        exit  # <-- Problem: exits script entirely
    elif [[ "$selection" == "Options" ]]; then
        micro options.sh
        # <-- Problem: loop continues to top, runs launch_amiberry
    fi
done

    Terminal: The exit command terminates main.sh. When running via systemd getty, the service restarts automatically, which relaunches Amiberry.
    Options: After the editor closes, the loop continues to the top, calling launch_amiberry before showing the menu again.

Solution:

Added an inner loop around the exit menu. This allows Terminal and Options to return to the menu without restarting Amiberry:

while [[ 1 ]]; do
    launch_amiberry

    # Inner loop for exit menu
    while [[ 1 ]]; do
        # ... build and show menu ...

        if [[ "$selection" == *"(A)"* ]]; then
            break  # Break inner loop to restart Amiberry
        elif [[ "$selection" == *"(T)"* ]]; then
            bash   # Spawn shell; returns to menu when user exits
        elif [[ "$selection" == *"(E)"* ]]; then
            # Edit options; inner loop continues to show menu
            script -q -c "micro options.sh" /dev/null
        elif [[ "$selection" == *"(R)"* ]]; then
            sudo /sbin/shutdown -r now
        elif [[ "$selection" == *"(S)"* ]]; then
            sudo /sbin/shutdown -h now
        fi
    done
done

Issue 2: String Comparison Failures

Symptoms: The Options menu item comparison failed intermittently.

Root Cause:

The Options menu item uses variable expansion:

menu_item_options="(E)dit ${application_name_cc} Options"

Exact string comparison could fail due to subtle differences in how the string was written to the menu file and read back.

Solution:

Changed all menu comparisons to use substring pattern matching with unique hotkey letters:

# Before (exact match)
if [[ "${abe_menu_selection}" == "${menu_item_options}" ]]; then

# After (substring pattern match)
if [[ "${abe_menu_selection}" == *"(E)"* ]]; then

Each menu item has a unique hotkey letter: (A)miberry, (E)dit, (T)erminal, (R)eboot, (S)hutdown. This approach is more robust.
Issue 3: Editor Fails to Open (TTY Error)

Symptoms:

open /dev/tty: no such device or address
Fatal: Micro could not initialize a Screen.

Root Cause:

The non-root installation uses a systemd getty override to launch AmiBootEnv:

ExecStart=-/usr/bin/su - amiberry -c "/AmiBE/bin/launch.sh"

The su -c command does not allocate a controlling terminal (tty) for the child process. Terminal-based editors like micro and nano require a tty to function.

Solution:

Wrapped the editor command with script to allocate a pseudo-terminal:

# Before
micro -colorscheme=material-tc -keymenu=true "${my_path}/options.sh"

# After
script -q -c "micro -colorscheme=material-tc -keymenu=true '${my_path}/options.sh'" /dev/null

The script command:

    -q - Quiet mode (no start/done messages)
    -c "command" - Run specified command instead of interactive shell
    /dev/null - Discard the typescript file (recording not needed)

Issue 4: Terminal Shows Bash Errors

Symptoms:

bash: cannot set terminal process group (913): Inappropriate ioctl for device
bash: no job control in this shell

Root Cause:

Same as Issue 3 - when spawning bash via systemd's su -c, there's no controlling terminal allocated. Bash detects this and prints warnings about being unable to set up job control.

Solution:

Wrapped the bash command with script to allocate a pseudo-terminal, and added IP address display for convenience:

# Before
bash

# After
echo "IP Address(es):"
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | while read ip; do
    echo "  $ip"
done
script -q -c "bash" /dev/null

This provides a proper interactive shell with job control, and displays the system's IP address(es) for easy SSH access.
Files Modified
New Files
File 	Description
main.sh 	Patched version of main.sh with all fixes
Install-nonroot.sh 	Modified installer for non-root operation
DEVLOG.md 	This development log
Changes to Install-nonroot.sh

    Creates dedicated amiberry user with appropriate group memberships
    Prompts for user password during installation (for SSH/sudo access)
    Configures udev rules for hardware access (input, video, USB)
    Sets up sudoers for shutdown/reboot/mount commands
    Configures systemd getty override for tty1
    Copies patched main.sh instead of using sed patches

Changes in main.sh

    Inner loop structure for exit menu (lines 231-285)
    Substring pattern matching for menu selection comparison
    bash spawn instead of exit for Terminal option
    script wrapper for editor and bash to allocate pseudo-terminal
    sudo prefix for shutdown commands (non-root operation)
    IP address display when dropping to terminal (for SSH access)

Notes for Upstream

The core issue is that the original script assumes it will always have a controlling terminal and that exit will return to a login prompt. When running via systemd getty with su -c, these assumptions don't hold.

The fixes are backward-compatible with the root installation if:

    The inner loop structure is adopted (improves UX regardless of root/non-root)
    The script wrapper is used conditionally (only when no tty is available)
    The sudo commands are made conditional based on user privileges

Alternatively, the systemd getty override could use agetty --autologin amiberry instead of su -c, which properly allocates a controlling terminal. However, this would require additional configuration to run launch.sh from the user's profile.
Author

Modifications by: VK3HEG Date: January 2026
