from flask import Flask, render_template, request
import atexit
import logging
import os
import shelve
import sqlite3

app = Flask(__name__)
db_path = os.environ.get('DB_PATH', '/data/db.sqlite3')

def cursortodict(cursor):
    desc = cursor.description
    column_names = [col[0] for col in desc]
    data = [dict(zip(column_names, row))  
            for row in cursor.fetchall()]
    return data

def get_db_connection():
    con = sqlite3.connect(db_path)
    con.row_factory = sqlite3.Row
    con.execute('CREATE TABLE IF NOT EXISTS pis (mac TEXT PRIMARY KEY, name TEXT, last_seen_ip TEXT, url TEXT, rotation INT, zoom INT)')
    con.commit()
    return con

@app.route('/')
def home():

    con = get_db_connection()
    cur = con.cursor()
    cur.execute('SELECT * FROM pis')
    data = cursortodict(cur)
    return render_template('index.html', data=data)

@app.route('/pi')
def pi():
    con = get_db_connection()
    mac = request.args.get('mac')
    ip = request.args.get('ip', 'Not yet seen')
    if mac == None or mac == "None" or mac == "":
        return '{"error": "No MAC address provided"}', 400
    pi = con.execute('SELECT * FROM pis WHERE mac = ?', (mac,)).fetchone()
    if pi:
        con.execute('UPDATE pis SET last_seen_ip=? WHERE mac=?', (ip, mac))
        con.commit()
    else:
        con.execute('INSERT INTO pis (mac, last_seen_ip) VALUES (?, ?)', (mac, ip))
        con.commit()

    cur = con.cursor()
    cur.execute('SELECT * FROM pis WHERE mac = ?', (mac,))

    pi = cursortodict(cur)[0]
    if pi["url"] == None:
        return '{"error": "No configuration for a pi with that MAC address"}'
    pi["status"] = 0
    return pi

@app.route('/update')
def update():
    con = get_db_connection()
    originalmac = request.args.get('originalmac')
    mac = request.args.get('mac')
    url = request.args.get('url')
    name = request.args.get('name')
    rotation = request.args.get('rotation')
    zoom = request.args.get('zoom')

    if mac == None or mac == "None" or mac == "":
        return '{"error": "No MAC address provided"}', 400

    
    if originalmac:
        con.execute('UPDATE pis SET mac=?, name=?, url=?, rotation=?, zoom=? WHERE mac=?', (mac, name, url, rotation, zoom, originalmac))
    else:
        con.execute('INSERT INTO pis (mac, name, url, rotation, zoom) VALUES (?, ?, ?, ?, ?)', (mac, name, url, rotation, zoom))

    con.commit()
    cur = con.cursor()
    cur.execute('SELECT * FROM pis WHERE mac = ?', (mac,))
    pi = cursortodict(cur)
    return pi

@app.route('/delete')
def delete():
    con = get_db_connection()
    mac = request.args.get('mac')

    cur = con.cursor()
    pi = cur.execute('SELECT * FROM pis WHERE mac = ?', (mac,)).fetchone()

    if pi == None:
        return '{"error": "No Pi with that MAC address"}', 404

    con.execute('UPDATE pis SET name=null, url=null, rotation=null, zoom=null  WHERE mac = ?', (mac,))
    con.commit()
    return '{"success": "Deleted"}'

@app.route('/forget')
def forget():
    con = get_db_connection()
    mac = request.args.get('mac')

    cur = con.cursor()
    pi = cur.execute('SELECT * FROM pis WHERE mac = ?', (mac,)).fetchone()

    if pi == None:
        return '{"error": "No Pi with that MAC address"}', 404

    con.execute('DELETE FROM pis WHERE mac = ?', (mac,))
    con.commit()
    return '{"success": "Removed"}'


if __name__ == "__main__":
    port = int(os.environ.get('PORT', 5000))
    app.run(debug=True, host='0.0.0.0', port=port)