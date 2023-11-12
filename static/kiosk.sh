#!/bin/bash
# 
# Version 1
# 
# TODO: Read manager URL from file with default
MANAGERURL=

MYMAC=$(ip link show dev eth0 | grep ether | sed 's/.*ether //' | sed "s/ .*//")
echo "My MAC: $MYMAC"

MYDATA=$(curl -m5 -s $MANAGERURL/pi?mac=$MYMAC)
echo "My Data: $MYDATA"

MYNAME=$(echo "$MYDATA" | jq .name)
MYURL=$(echo "$MYDATA" | jq .url)
MYROTATION=$(echo "$MYDATA" | jq .rotation)
MYZOOM=$(echo "$MYDATA" | jq .zoom)

echo "Name: $MYNAME"
echo "URL: $MYURL"
echo "Rotation: $MYROTATION"
echo "Zoom: $MYZOOM"

if [ -n $MYNAME ]; then
	sudo hostnamectl set-hostname "GTpi_$MYNAME"
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

xrandr --output HDMI-1 --rotate $ROTATE

if [ -z $MYURL ]; then
	echo "Uh oh, something went wrong and I couldn't find my URL"
	if [ -f ~/cachedURL ]; then
		echo "But I found a cached URL so I'm using that"
		MYURL=$(cat ~/cachedURL)
	else
		MYIP=$(ip addr show | grep 192 | sed 's/.*inet //; s/ .*//')
		echo "Showing debug screen"
		echo "<body style='background-color: black;'><h1 style='color: #121212; font-size: 100;'>MY MAC: $MYMAC <br/>MY DATA: $DATA <br/>MY IP: $MYIP </h1></body>" > /tmp/debug.html
		MYURL="file:///tmp/debug.html"
	fi
else
	echo $MYURL > ~/cachedURL
fi

xset -dpms     # disable DPMS (Energy Star) features.
xset s off     # disable screen saver
xset s noblank # don't blank the video device

unclutter -idle 0.5 -root & # hide X mouse cursor unless mouse activated

sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' /home/pi/.config/chromium/Default/Preferences
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' /home/pi/.config/chromium/Default/Preferences
rm /home/pi/.config/chromium/SingletonLock

echo "Opening: $MYURL"
chromium-browser --noerrdialogs --disable-infobars --kiosk --incognito --app=$MYURL &

sleep infinity;
