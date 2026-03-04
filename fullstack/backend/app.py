from flask import Flask, request, jsonify
import pymysql
import os

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST")
DB_USER = "admin"
DB_PASS = "StrongPassword123!"
DB_NAME = "mysql"

def get_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME
    )

@app.route("/health")
def health():
    return "Healthy"

@app.route("/users", methods=["POST"])
def create_user():
    data = request.json
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("CREATE TABLE IF NOT EXISTS users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255))")
    cursor.execute("INSERT INTO users (name) VALUES (%s)", (data["name"],))
    conn.commit()
    conn.close()
    return jsonify({"message": "User created"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)