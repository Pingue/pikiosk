from flask import Flask, render_template, request
import netifaces
import os
import re
import socket
import subprocess


app = Flask(__name__)

@app.route('/')
def home():
    def_gw_device = netifaces.gateways()['default'][netifaces.AF_INET][1]
    macaddr = netifaces.ifaddresses(def_gw_device)[netifaces.AF_LINK][0]['addr']
    return render_template('index.html', mac=macaddr, rotation="90")


if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)