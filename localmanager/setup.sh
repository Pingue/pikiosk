#!/bin/bash
# Check we are running under bash
if [ ! "$BASH_VERSION" ] ; then
        echo "Not running under bash, exiting"
        exit 0
fi
# Check we are running as pi
if [ "$USER" != "pi" ] ; then
        echo "Please run as pi"
        exit 1
fi
# Check we are on raspbian
if [ ! -f /etc/os-release ] ; then
        echo "Cannot find /etc/os-release, are you on raspbian?"
        exit 1
fi
if ! grep -q "Raspbian" /etc/os-release ; then
        echo "This script is intended for raspbian, exiting"
        exit 1
fi

# Prompt for details
echo -n "Manager URL: "
read manager
echo $manager > /opt/pikiosk/manager
echo -n "Fetch logo file: "
read logo

# Install dependencies
echo "Installing dependencies..."
sudo apt install -y git python3 python3-pip
sudo pip3 install ansible ansible-playbook

# Fetch app from github
echo "Fetching app from github..."
sudo mkdir /opt/pikiosk
sudo chown pi: /opt/pikiosk
git clone https://github.com/Pingue/pikiosk-localmanager.git /opt/pikiosk
wget $logo -O /opt/pikiosk/logo.png

# Run ansible playbook to set up the app
echo "Running ansible playbook..."
ansible-playbook /opt/pikiosk/ansible/setup.yml