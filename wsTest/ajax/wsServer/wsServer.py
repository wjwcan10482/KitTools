import os
import time

from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# 日志文件路径
LOG_FILE = '/var/log/test'

@app.route('/api/log')
def get_log():
    size = os.path.getsize(LOG_FILE)
    start = int(request.args.get('start', size))
    with open(LOG_FILE, 'rb') as f:
        f.seek(start)
        data = f.read().decode('utf-8')
    return jsonify({'data': data, 'size': size})

if __name__ == '__main__':
    app.run(host="0.0.0.0",debug=True)
