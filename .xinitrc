#!/bin/sh

# /etc/X11/xinit/xinitrc
#
# global xinitrc file, used by all X sessions started by xinit (startx)

# invoke global X session script
# . /etc/X11/Xsession
# export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export INPUT_METHOD=fcitx
export DWM=~/.dwm
xrandr --output HDMI-0 --mode 1920x1080 --rate 120 --primary
# mouse dpi
xinput --set-prop 10 'libinput Accel Speed' -0.3


exec dwm
