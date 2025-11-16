#!/bin/bash

# Clean up stale locks
vncserver -kill $DISPLAY 2>/dev/null || true
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1

echo "Starting VNC server on $DISPLAY with resolution $RESOLUTION"
vncserver $DISPLAY -geometry $RESOLUTION -depth 24 -localhost no -SecurityTypes VncAuth

# Allow VNC/XFCE to initialize
sleep 3

# Apply wallpaper (ignore errors)
xfconf-query -c xfce4-desktop \
  -p /backdrop/screen0/monitorVirtual-1/workspace0/last-image \
  -s /usr/share/backgrounds/xfce/ac6-onlinepc-wallpaper.jpg || true

xfconf-query -c xfce4-desktop \
  -p /backdrop/screen0/monitorVirtual-1/workspace0/image-style \
  -s 5 || true

# Disable blanking
xset s off || true
xset -dpms || true
xset s noblank || true

# Kill old websockify
pkill -f websockify 2>/dev/null || true

echo "Starting noVNC on port $NO_VNC_PORT..."
websockify --web=/usr/share/novnc/ $NO_VNC_PORT localhost:$VNC_PORT &

echo "=============================================================="
echo "   AC6 OnlinePC Container Started "
echo "=============================================================="
echo ""
echo "Open noVNC in your browser at:"
echo "  http://localhost:8080"
echo ""
echo "Login credentials:"
echo "  Username: ${USERNAME}"
echo "  Password: ${PASSWORD}"
echo ""
echo "VNC Server running on:"
echo "  Display: ${DISPLAY}"
echo "  Port: ${VNC_PORT}"
echo "=============================================================="
echo ""

# Follow VNC log to keep container alive
tail -F /home/$USERNAME/.vnc/*.log
