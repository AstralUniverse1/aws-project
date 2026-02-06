import os
import mysql.connector
from flask import Flask, Response

app = Flask(__name__)

def fetch_db_value():
    cfg = {
        "host": os.environ.get("MYSQL_HOST", ""),
        "port": int(os.environ.get("MYSQL_PORT", "3306")),
        "user": os.environ.get("MYSQL_USER", ""),
        "password": os.environ.get("MYSQL_PASSWORD", ""),
        "database": os.environ.get("MYSQL_DATABASE", ""),
        "connection_timeout": 3,
    }

    if not cfg["host"] or not cfg["user"] or not cfg["database"]:
        return "DB not configured yet"

    conn = mysql.connector.connect(**cfg)
    cur = conn.cursor()
    cur.execute("SELECT v FROM app_config WHERE k='deployment_version';")
    row = cur.fetchone()
    cur.close()
    conn.close()
    return row[0] if row else "No deployment_version"

@app.get("/")
def index():
    db_value = fetch_db_value()
    app_version = os.environ.get("APP_VERSION", "unknown")

    html = f"""
<!doctype html>
<html>
  <head><meta charset="utf-8"><title>Commit Lab</title></head>
  <body>
    <h1>Hello Commit Dror Levy</h1>
    <img src="/logo.png" alt="logo" style="max-height:120px;">
    <p><b>DB value:</b> {db_value}</p>
    <p><b>Build version:</b> {app_version}</p>
  </body>
</html>
"""
    return Response(html, mimetype="text/html")
