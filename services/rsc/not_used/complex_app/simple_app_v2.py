#!/usr/bin/env python3

from flask import Flask, render_template_string, request, redirect, jsonify
import redis
import psycopg2
import os

app = Flask(__name__)

# Configuration Redis
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')

# Configuration PostgreSQL
PG_HOST = os.getenv('POSTGRES_HOST', 'localhost')
PG_PORT = int(os.getenv('POSTGRES_PORT', 5432))
PG_USER = os.getenv('POSTGRES_USER', 'postgres')
PG_PASSWORD = os.getenv('POSTGRES_PASSWORD', '')
PG_DB = os.getenv('POSTGRES_DB', 'postgres')

def get_redis():
    return redis.Redis(host=REDIS_HOST, port=REDIS_PORT, password=REDIS_PASSWORD, decode_responses=True)

def get_pg_conn():
    return psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        user=PG_USER,
        password=PG_PASSWORD,
        database=PG_DB
    )

def init_db():
    # Init Redis
    r = get_redis()
    if not r.exists('user:clicks'):
        r.set('user:clicks', 0)
    if not r.exists('user:refreshes'):
        r.set('user:refreshes', 0)
    
    # Init PostgreSQL
    conn = get_pg_conn()
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS admin_stats (id INTEGER PRIMARY KEY, clicks INTEGER, refreshes INTEGER)')
    c.execute('INSERT INTO admin_stats (id, clicks, refreshes) VALUES (1, 0, 0) ON CONFLICT (id) DO NOTHING')
    conn.commit()
    conn.close()

init_db()

@app.route('/health/live')
def liveness():
    return jsonify({"status": "ok"}), 200

@app.route('/health/ready')
def readiness():
    try:
        r = get_redis()
        r.ping()
        conn = get_pg_conn()
        conn.close()
        return jsonify({"status": "ready"}), 200
    except Exception as e:
        return jsonify({"status": "not ready", "error": str(e)}), 503

@app.route('/', methods=['GET', 'POST'])
def index():
    r = get_redis()
    
    if request.method == 'POST':
        if 'user_click' in request.form:
            r.incr('user:clicks')
        elif 'admin_click' in request.form:
            conn = get_pg_conn()
            c = conn.cursor()
            c.execute('UPDATE admin_stats SET clicks = clicks + 1 WHERE id = 1')
            conn.commit()
            conn.close()
        return redirect('/')
    
    # Increment refreshes
    r.incr('user:refreshes')
    conn = get_pg_conn()
    c = conn.cursor()
    c.execute('UPDATE admin_stats SET refreshes = refreshes + 1 WHERE id = 1')
    conn.commit()
    
    # Get stats
    user_clicks = r.get('user:clicks')
    user_refreshes = r.get('user:refreshes')
    
    c.execute('SELECT clicks, refreshes FROM admin_stats WHERE id = 1')
    admin_clicks, admin_refreshes = c.fetchone()
    conn.close()

    html = """
    <html>
    <head>
        <title>Test App</title>
        <style>
            body { font-family: Arial; padding: 20px; }
            .section { border: 2px solid #ccc; padding: 20px; margin: 20px 0; border-radius: 8px; }
            .user { border-color: #4CAF50; }
            .admin { border-color: #2196F3; }
            h2 { margin-top: 0; }
            button { padding: 10px 20px; font-size: 16px; cursor: pointer; }
        </style>
    </head>
    <body>
        <h1>Simple App - Dual Storage</h1>
        
        <div class="section user">
            <h2>👤 Section User (Redis)</h2>
            <p>Clics: {{ user_clicks }}</p>
            <p>Refreshes: {{ user_refreshes }}</p>
            <form method="post">
                <button type="submit" name="user_click">Cliquer (User)</button>
            </form>
        </div>
        
        <div class="section admin">
            <h2>⚙️ Section Admin (PostgreSQL)</h2>
            <p>Clics: {{ admin_clicks }}</p>
            <p>Refreshes: {{ admin_refreshes }}</p>
            <form method="post">
                <button type="submit" name="admin_click">Cliquer (Admin)</button>
            </form>
        </div>
    </body>
    </html>
    """
    return render_template_string(html, 
                                 user_clicks=user_clicks, 
                                 user_refreshes=user_refreshes,
                                 admin_clicks=admin_clicks,
                                 admin_refreshes=admin_refreshes)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)