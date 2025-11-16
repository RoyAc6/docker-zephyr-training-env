#!/bin/bash

# Kill stale VNC sessions
vncserver -kill $DISPLAY 2>/dev/null || true
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1

# Auto-restarting VNC loop
(
  while true; do
      echo "Starting VNC server on $DISPLAY with resolution $RESOLUTION"
      vncserver $DISPLAY -geometry $RESOLUTION -depth 24 -localhost no -SecurityTypes VncAuth
      echo "VNC server exited. Restarting in 2s..."
      sleep 2
  done
) &

# Give session a bit of time before applying settings
sleep 5

# Force wallpaper
DISPLAY=$DISPLAY xfconf-query -c xfce4-desktop \
  -p /backdrop/screen0/monitorVirtual-1/workspace0/last-image \
  -s /usr/share/backgrounds/xfce/ac6-onlinepc-wallpaper.jpg || true

DISPLAY=$DISPLAY xfconf-query -c xfce4-desktop \
  -p /backdrop/screen0/monitorVirtual-1/workspace0/image-style \
  -s 5 || true

# Disable screen blanking
DISPLAY=$DISPLAY xset s off || true
DISPLAY=$DISPLAY xset -dpms || true
DISPLAY=$DISPLAY xset s noblank || true

# Kill old websockify if any
pkill -f websockify || true

# Start noVNC
websockify --web=/usr/share/novnc/ $NO_VNC_PORT localhost:$VNC_PORT &

# Keep container alive
tail -F /home/$USERNAME/.vnc/*.log

