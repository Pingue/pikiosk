#!/bin/bash

export LC_ALL=en_GB.UTF-8

while [[ $# -gt 0 ]]; do
  case $1 in
    -m|--skip-manager)
      SKIPMANAGER=1
      shift # past argument
      ;;
    -l|--skip-logo)
      SKIPLOGO=1
      shift # past argument
      ;;
#    --numberoftimes)
#      TIMES="$2"
#      shift # past argument
#      shift # past value
#      ;;
    -*|--*|*)
      echo "Unknown option $1"
      exit 1
      ;;
#    *)
#      POSITIONAL_ARGS+=("$1") # save positional arg
#      shift # past argument
#      ;;
  esac
done

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
if ! grep -q "Debian" /etc/os-release ; then
        echo "This script is intended for raspbian (Debian), exiting"
        exit 1
fi

# Prompt for details
if [[ -z $SKIPMANAGER ]]; then
	echo -n "Manager URL: "
	read manager
fi
if [[ -z $SKIPLOGO ]]; then
	echo -n "Fetch logo file: "
	read logo
fi

# Install dependencies
echo "Installing dependencies..."
sudo apt install -y git python3 python3-pip pipx
pipx install ansible
pipx install ansible-core
pipx ensurepath

# Fetch app from github
echo "Fetching app from github..."
sudo mkdir /opt/pikiosk
sudo chown pi: /opt/pikiosk
git clone https://github.com/Pingue/pikiosk-localmanager.git /opt/pikiosk
if [[ -z $SKIPMANAGER ]]; then
	echo $manager > /opt/pikiosk/manager
fi
if [[ -z $SKIPLOGO ]]; then
	wget $logo -O /opt/pikiosk/logo.png
fi

# Run ansible playbook to set up the app
echo "Running ansible playbook..."
/home/pi/.local/bin/ansible-galaxy collection install community.general
/home/pi/.local/bin/ansible-playbook /opt/pikiosk/ansible/setup.yml
