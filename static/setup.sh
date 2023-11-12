#!/bin/bash
# TODO: Ensure run as pi user
# TODO: Add check for existing install
# TODO: Default for manager URL
# TODO: Read manager URL from file
# TODO: OS check
mkdir /opt/pikiosk
echo -n "Manager URL: "
read manager
echo $manager > /opt/pikiosk/manager

echo "Fetching app from github..."
wget https://raw.githubusercontent.com/pingue/pikiosk/master/static/kiosk.sh -O /opt/pikiosk/kiosk.sh
wget https://raw.githubusercontent.com/pingue/pikiosk/master/static/localmanager/app.py -O /opt/pikiosk/app.py
wget https://raw.githubusercontent.com/pingue/pikiosk/master/static/localmanager/requirements.txt -O /opt/pikiosk/requirements.txt

echo "Installing app"
sudo apt install -y python3-pip jq curl chromium-browser x11-xserver-utils unclutter nginx uwsgi uwsgi-plugin-python3
pip3 install -r /app/requirements.txt

sudo bash -c 'cat <<EOF > /etc/motd
########### PIKIOSK  ############

This Pi is managed with pikiosk image.

#################################
EOF'

echo "Setting up webserver"
sudo rm /etc/nginx/sites-enabled/default
sudo cat <<EOF > /etc/nginx/sites-enabled/piadmin
upstream uwsgicluster {

    server 127.0.0.1:8080;
    # server 127.0.0.1:8081;
    # ..
    # .

}
server {

    # Running port
    listen 80;

    # Settings to by-pass for static files 
    location ^~ /static/  {
        # Example:
        # root /full/path/to/application/static/file/dir;
        root /app/static/;
    }
    
    # Serve a static file (ex. favico) outside static dir.
    location = /favico.ico  {
        root /opt/pikiosk/favico.ico;
    }

    # Proxying connections to application servers
    location / {
    
        include            uwsgi_params;
        uwsgi_pass         uwsgicluster;

        proxy_redirect     off;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Host \$server_name;
    
    }
}
EOF
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "Setting up uwsgi app server"
sudo cat <<EOF > /etc/uwsgi/apps-enabled/piadmin.ini
[uwsgi]
plugins = python3
chdir = /opt/pikiosk
module = app:app
master = true
processes = 5
socket =
chmod-socket = 660
vacuum = true
die-on-term = true
EOF
sudo systemctl restart uwsgi

echo "Setting up autostart"
sudo cat <<EOF > /etc/systemd/system/kiosk.service
[Unit] 
Description=Kiosk
After=network.target

[Service]
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
ExecStart=/opt/pikiosk/kiosk.sh
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF
sudo systemctl enable kiosk.service
sudo systemctl start kiosk.service