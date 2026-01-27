#!/usr/bin/env python3

from flask import Flask, render_template_string, request, redirect, jsonify
import sqlite3

app = Flask(__name__)
DB_PATH = '/app/data/data.db'

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS stats (id INTEGER PRIMARY KEY, clicks INTEGER, refreshes INTEGER)')
    c.execute('INSERT OR IGNORE INTO stats (id, clicks, refreshes) VALUES (1, 0, 0)')
    conn.commit()
    conn.close()

init_db()

@app.route('/health/live')
def liveness():
    """Liveness probe - vérifie que l'application est en cours d'exécution"""
    return jsonify({"status": "ok"}), 200

@app.route('/health/ready')
def readiness():
    """Readiness probe - vérifie que l'application peut traiter des requêtes"""
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute('SELECT 1 FROM stats LIMIT 1')
        c.fetchone()
        conn.close()
        return jsonify({"status": "ready"}), 200
    except Exception as e:
        return jsonify({"status": "not ready", "error": str(e)}), 503

@app.route('/', methods=['GET', 'POST'])
def index():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    if request.method == 'POST':
        c.execute('UPDATE stats SET clicks = clicks + 1 WHERE id = 1')
        conn.commit()
        return redirect('/')

    c.execute('UPDATE stats SET refreshes = refreshes + 1 WHERE id = 1')
    conn.commit()

    c.execute('SELECT clicks, refreshes FROM stats WHERE id = 1')
    clicks, refreshes = c.fetchone()
    conn.close()

    html = """
    <html>
    <head><title>Test App</title></head>
    <body>
        <h1>Simple app</h1>
        <p>Number of clics : {{ clicks }}</p>
        <p>Number of refresh : {{ refreshes }}</p>
        <form method="post">
            <button type="submit">Cliquez ici</button>
        </form>
    </body>
    </html>
    """
    return render_template_string(html, clicks=clicks, refreshes=refreshes)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
