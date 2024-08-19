from flask import Flask, render_template, request, redirect
import json
import netifaces
import os
import re
import socket
import subprocess


app = Flask(__name__)

@app.route('/')
def home():
    def_gw_device = netifaces.gateways()['default'][netifaces.AF_INET][1]
    try:
        manager = open('./manager', 'r').read()
    except:
        manager = ""
    macaddr = netifaces.ifaddresses(def_gw_device)[netifaces.AF_LINK][0]['addr']
    try:
        cachedDetails = json.load(open('./cacheddetails'))
    except:
        cachedDetails = {'name': '', 'url': '', 'rotation': 0, 'zoom': 0}
    name = cachedDetails['name']
    url = cachedDetails['url']
    rotation = cachedDetails['rotation']
    zoom = cachedDetails['zoom']
    return render_template('index.html', manager=manager, mac=macaddr, name=name, url=url, rotation=rotation, zoom=zoom)
    

@app.route('/save')
def update():
    manager = request.args.get('manager')
    f = open("./manager", "w")
    f.write(manager)
    f.close()
    url = request.args.get('url')
    name = request.args.get('name')
    rotation = request.args.get('rotation')
    zoom = request.args.get('zoom')
    cachedDetails = {'name': name, 'url': url, 'rotation': rotation, 'zoom': zoom}
    json.dump(cachedDetails, open('./cacheddetails', 'w'))
    return redirect("/")

@app.route('/reboot')
def reboot():
    subprocess.call(['reboot'])
    return "Rebooting... Please refresh the page after a short while."

@app.route('/reload')
def reload():
    command = 'systemctl restart --user pikiosk.service'
    subprocess.call(command.split(" "))
    return redirect("/")

@app.route('/refresh')
def refresh():
    command = '/usr/bin/xdotool getactivewindow key F5'
    subprocess.call(command.split(" "), env={"DISPLAY": ":0"})
    return redirect("/")

if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)