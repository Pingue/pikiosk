#!/bin/bash
MANAGERURL=$(cat /opt/pikiosk/manager)

MYPIKIOSKVERSION=$(git -C /opt/pikiosk/ describe --tags)
MYOS=$(cat /etc/os-release | grep PRETTY_NAME | sed 's/.*AME..\(.*\).$/\1/')

MYIP=$(ip route show default | sed 's/.*src //' | sed 's/ .*//')
echo "My IP: $MYIP"
MYMAC=$(ip addr show | grep $MYIP -B1 | head -n1 | sed 's/.*ether //' | sed 's/ .*//')
echo "My MAC: $MYMAC"

curl "$MANAGERURL/checkin?mac=$MYMAC&ip=$MYIP&version=$MYPIKIOSKVERSION" --data-urlencode "os=$MYOS"