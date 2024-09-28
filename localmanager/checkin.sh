#!/bin/bash
MANAGERURL=$(cat /opt/pikiosk/manager)

MYIP=$(ip route show default | sed 's/.*src //' | sed 's/ .*//')
echo "My IP: $MYIP"
MYMAC=$(ip addr show | grep $MYIP -B1 | head -n1 | sed 's/.*ether //' | sed 's/ .*//')
echo "My MAC: $MYMAC"
MYPIKIOSKVERSION=$(git -C /opt/pikiosk/ describe --tags)
echo "My Pikiosk Version: $MYPIKIOSKVERSION"
MYOS=$(cat /etc/os-release | grep PRETTY_NAME | sed 's/.*AME..\(.*\).$/\1/')
echo "My OS: $MYOS"

curl -G "$MANAGERURL/checkin?mac=$MYMAC&ip=$MYIP&version=$MYPIKIOSKVERSION" --data-urlencode "os=$MYOS"