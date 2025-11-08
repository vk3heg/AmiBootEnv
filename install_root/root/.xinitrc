# .xinitrc for AmiBootEnv

# Start window manager
ratpoison &

# The second arg is required to keep xterm open after Amiberry exits
/usr/bin/X11/xterm -e "/AmiBE/bin/main.sh;/bin/bash"
