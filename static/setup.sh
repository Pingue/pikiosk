#!/bin/bash
# TODO: Ensure script and service are both run as whatever autologin user is configged
# TODO: Add check for existing install
# TODO: OS check
# TODO: Write localmanager service
# TODO: Integrate localmanager service
# TODO: on setup, prompt for background image URL which gets curled locally
# FIXME: some way of getting this into place: /opt/pikiosk/logo.png
# TODO: systemd unit should be created in ~/.local/share/systemd/user
# TODO: Set default wallpaper
# TODO: /boot/cmdline.txt --- logo.nologo
# TODO: Not working on first boot (trying before network?)
# TODO: Occasional race condition causing login to fail because pikiosk has already taken DISPLAY=:0. maybe pause until a display is already available
# TODO: screensaver isn't disabled
# TODO: cachedURL should be cachedData and include rotation etc

sudo rm /usr/share/plymouth/themes/pix/splash.png 
sudo rm /usr/share/rpd-wallpaper/logo.png
sudo ln -s /opt/pikiosk/logo.png /usr/share/plymouth/themes/pix/splash.png 
sudo ln -s /opt/pikiosk/logo.png /usr/share/rpd-wallpaper/logo.png
sudo rm /etc/alternatives/desktop-background
sudo ln -s /opt/pikiosk/logo.png /etc/alternatives/desktop-background
sudo rm /etc/alternatives/desktop-login-background
sudo ln -s /opt/pikiosk/logo.png /etc/alternatives/desktop-login-background
sudo sed -i 's|^wallpaper=.*|wallpaper=/opt/pikiosk/logo.png|' /etc/lightdm/pi-greeter.conf
echo "background=/opt/pikiosk/logo.png" | sudo tee --append /etc/lightdm/lightdm-gtk-greeter.conf

cat <<EOF | sudo tee /etc/xdg/pcmanfm/LXDE-pi/desktop-items-0.conf
[*]
desktop_bg=#000000
desktop_shadow=#000000
desktop_fg=#000000
desktop_font=PibotoLt 12
wallpaper=/opt/pikiosk/logo.png
wallpaper_mode=crop
show_documents=0
show_trash=0
show_mounts=0
EOF


# TODO: THIS IS NOT IDEMPOTENT
cat <<EOF | sudo tee --append /boot/config.txt
[pi4]
arm_boost=1

[all]
hdmi_force_hotplug=1
hdmi_group=1
hdmi_mode=16
hdmi_group:0=1
hdmi_mode:0=16
hdmi_group:1=1
hdmi_mode:1=16
dtparam=i2c_arm=on
dtparam=spi=off
dtoverlay=disable-bt
dtoverlay=disable-wifi
disable_splash=1
gpu_mem=128

EOF
# Below line was previously here, but it seems to be causing issues with the display, this might need to be a sed instead
# dtoverlay=vc4-fkms-v3d

sudo mkdir /opt/pikiosk
sudo chown $USER: /opt/pikiosk
echo -n "Manager URL: "
read manager
echo $manager > /opt/pikiosk/manager

echo "Fetching app from github..." #TODO: use git instead
wget https://raw.githubusercontent.com/pingue/pikiosk/main/static/kiosk.sh -O /opt/pikiosk/kiosk.sh
wget https://raw.githubusercontent.com/pingue/pikiosk/main/static/localmanager/localmanager.py -O /opt/pikiosk/app.py
wget https://raw.githubusercontent.com/pingue/pikiosk/main/static/localmanager/requirements.txt -O /opt/pikiosk/requirements.txt
wget https://raw.githubusercontent.com/pingue/pikiosk/main/static/localmanager/uwsgi.txt -O /opt/pikiosk/uwsgi.txt
mkdir /opt/pikiosk/templates
wget https://raw.githubusercontent.com/pingue/pikiosk/main/static/localmanager/templates/index.html -O /opt/pikiosk/templates/index.html
chmod +x /opt/pikiosk/kiosk.sh

echo "Installing app"
sudo apt install -y python3-pip xdotool jq curl chromium-browser x11-xserver-utils unclutter nginx fbi
sudo pip3 install -r /opt/pikiosk/requirements.txt

cat <<EOF | sudo tee /etc/motd
########### PIKIOSK  ############

This Pi is managed with pikiosk image.

#################################
EOF

echo "Setting up webserver"
sudo rm /etc/nginx/sites-enabled/default
cat <<EOF | sudo tee /etc/nginx/sites-enabled/piadmin
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
        uwsgi_pass         unix:/opt/pikiosk/localmanager.sock;

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


cat <<EOF | sudo tee /lib/systemd/system/splashscreen.service
[Unit]
Description=Splash screen
DefaultDependencies=no
After=local-fs.target
[Service]
ExecStart=/usr/bin/fbi -d /dev/fb0 --noverbose -a /usr/share/plymouth/themes/pix/splash.png
StandardInput=tty
StandardOutput=tty
[Install]
WantedBy=sysinit.target
EOF

mkdir -p /home/pi/.local/share/systemd/user/

echo "Setting up localmanager service"
cat <<EOF | sudo tee /home/pi/.local/share/systemd/user/localmanager.service
[Unit] 
Description=Pi Localmanager
After=network.target

[Service]
WorkingDirectory=/opt/pikiosk
ExecStart=uwsgi --ini uwsgi.ini
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

echo "Setting up pikiosk autostart"
cat <<EOF | sudo tee /home/pi/.local/share/systemd/user/pikiosk.service
[Unit] 
Description=Pi Kiosk
After=network.target

[Service]
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
ExecStart=/opt/pikiosk/kiosk.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable pikiosk.service
systemctl --user start pikiosk.service

systemctl --user enable localmanager.service
systemctl --user start localmanager.service

sudo loginctl enable-linger pi
# TODO: change that user
sudo systemctl start ssh