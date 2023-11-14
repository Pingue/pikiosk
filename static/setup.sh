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

ln -s /opt/pikiosk/logo.png /usr/share/plymouth/themes/pix/splash.png 
ln -s /opt/pikiosk/logo.png /usr/share/rpd-wallpaper/logo.png
rm /etc/alternatives/desktop-background
ln -s /opt/pikiosk/logo.png /etc/alternatives/desktop-background
rm /etc/alternatives/desktop-login-background
ln -s /opt/pikiosk/logo.png /etc/alternatives/desktop-login-background
sed -i 's|^wallpaper=.*|wallpaper=/opt/pikiosk/logo.png|'
echo "background=/opt/pikiosk/logo.png" >> /etc/lightdm/lightdm-gtk-greeter.conf

cat <<EOF > ~/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
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
sudo cat <<EOF >> /boot/config.txt
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
dtoverlay=vc4-fkms-v3d
[pi4]
arm_boost=1
EOF


mkdir /opt/pikiosk
echo -n "Manager URL: "
read manager
echo $manager > /opt/pikiosk/manager

echo "Fetching app from github..."
wget https://raw.githubusercontent.com/pingue/pikiosk/master/static/kiosk.sh -O /opt/pikiosk/kiosk.sh
wget https://raw.githubusercontent.com/pingue/pikiosk/master/static/localmanager/app.py -O /opt/pikiosk/app.py
wget https://raw.githubusercontent.com/pingue/pikiosk/master/static/localmanager/requirements.txt -O /opt/pikiosk/requirements.txt
chmod +x /opt/pikiosk/kiosk.sh

echo "Installing app"
sudo apt install -y python3-pip jq curl chromium-browser x11-xserver-utils unclutter nginx uwsgi uwsgi-plugin-python3 fbi
pip3 install -r /opt/pikiosk/requirements.txt

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



sudo cat <<EOF > /lib/systemd/system/splashscreen.service
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


echo "Setting up autostart"
sudo cat <<EOF > /etc/systemd/system/pikiosk.service
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
sudo loginctl enable-linger michael
# TODO: change that user
sudo systemctl enable pikiosk.service
sudo systemctl start pikiosk.service
