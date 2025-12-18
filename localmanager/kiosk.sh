#!/bin/bash
#
# Version 1
#
export DISPLAY=:0

rm -f /tmp/debug.html

MANAGERURL=$(cat /opt/pikiosk/manager)

MYPIKIOSKVERSION=$(git -C /opt/pikiosk/ describe --tags)
MYOS=$(cat /etc/os-release | grep PRETTY_NAME | sed 's/.*AME..\(.*\).$/\1/')

MYIP=$(ip route show default | sed 's/.*src //' | sed 's/ .*//')
echo "My IP: $MYIP"

MYMAC=$(ip addr show | grep $MYIP -B1 | head -n1 | sed 's/.*ether //' | sed 's/ .*//')
echo "My MAC: $MYMAC"

MYHARDWARE=$(tr -d '\0' < /proc/device-tree/model)
echo "My Hardware: $MYHARDWARE"

MYDATA=$(curl -G -m5 -s "$MANAGERURL/pi?mac=$MYMAC&ip=$MYIP&version=$MYPIKIOSKVERSION" --data-urlencode "os=$MYOS" --data-urlencode "hardware=$MYHARDWARE")
echo "My Data: $MYDATA"

USING_CACHE=0

if [[ $MYDATA != "" ]]; then
        echo "Response received, caching details"
        echo $MYDATA > /opt/pikiosk/cacheddetails
else
        echo "Uh oh, something went wrong and I couldn't fetch my details"
        if [ -f /opt/pikiosk/cacheddetails ]; then
                echo "But I found cached details I'm using that"
                MYDATA=$(cat /opt/pikiosk/cacheddetails)
                echo "My Data: $MYDATA"
                USING_CACHE=1
        fi

fi

STATUS=$(echo "$MYDATA" | jq -r .status)
echo "My Status: $STATUS"

if [[ $STATUS != "0" ]]; then
        MYIP=$(ip addr show | grep 192 | sed 's/.*inet //; s/ .*//')
        echo "Showing debug screen"
        echo "<body style='background-color: black;'><h1 style='color: #121212; font-size: 100;'>MY MAC: $MYMAC <br/>MY DATA: $MYDATA <br/>MY IP: $MYIP </h1></body>" > /tmp/debug.html
        MYDATA='{"url": "file:///tmp/debug.html", "rotation": "0", "zoom": "1", "name": "unknown", "status": "1"}'
fi

MYNAME=$(echo "$MYDATA" | jq -r .name)
MYURL=$(echo "$MYDATA" | jq -r .url)
MYROTATION=$(echo "$MYDATA" | jq -r .rotation)
MYZOOM=$(echo "$MYDATA" | jq -r .zoom)

echo "Name: $MYNAME"
echo "URL: $MYURL"
echo "Rotation: $MYROTATION"
echo "Zoom: $MYZOOM"

if [ -n $MYNAME ]; then
        sudo hostnamectl set-hostname "pikiosk-$MYNAME"
fi

if [[ $MYROTATION -eq "0" ]]; then
        ROTATE="normal"
fi
if [[ $MYROTATION -eq "90" ]]; then
        ROTATE="left"
fi
if [[ $MYROTATION -eq "180" ]]; then
        ROTATE="inverted"
fi
if [[ $MYROTATION -eq "270" ]]; then
        ROTATE="right"
fi
xrandr --output HDMI-1 --rotate $ROTATE --mode 1920x1080 --refresh 59.940

# Get current screen resolution
SCREEN_RES=$(xrandr | grep '*' | awk '{print $1}' | head -n1)
SCREEN_WIDTH=$(echo $SCREEN_RES | cut -d'x' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_RES | cut -d'x' -f2)
echo "Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

xset -dpms     # disable DPMS (Energy Star) features.
xset s off     # disable screen saver
xset s noblank # don't blank the video device

unclutter -idle 0.5 -root & # hide X mouse cursor unless mouse activated

sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' ~/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences
rm ~/.config/chromium/SingletonLock

xhost +si:localuser:pi

# Show 1px amber border if using cached data
if [[ $USING_CACHE -eq 1 ]]; then
        echo "Displaying cache indicator border"
        # Create a 1-pixel amber border overlay using ImageMagick
        BORDER_WIDTH=$((SCREEN_WIDTH - 1))
        BORDER_HEIGHT=$((SCREEN_HEIGHT - 1))
        convert -size ${SCREEN_WIDTH}x${SCREEN_HEIGHT} xc:none \
                -fill none -stroke '#FFA500' -strokewidth 1 \
                -draw "rectangle 0,0 ${BORDER_WIDTH},${BORDER_HEIGHT}" \
                /tmp/cache_border.png
        
        # Display as persistent overlay using feh
        feh --geometry ${SCREEN_WIDTH}x${SCREEN_HEIGHT}+0+0 -x --borderless --on-root /tmp/cache_border.png &
fi

echo "Opening: $MYURL"
echo chromium --noerrdialogs --disable-infobars --kiosk --incognito --app=$MYURL --start-fullscreen --start-maximized --disable-features=HttpsFirstModeIncognito --password-store=basic
echo $DISPLAY

chromium --noerrdialogs --disable-infobars --kiosk --incognito --app=$MYURL --start-fullscreen --start-maximized --disable-features=HttpsFirstModeIncognito --password-store=basic
