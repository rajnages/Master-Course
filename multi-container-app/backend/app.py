from flask import Flask, jsonify
from flask_cors import CORS
from prometheus_flask_exporter import PrometheusMetrics
import redis
import pymongo
import os
import time

app = Flask(__name__)
# Enable CORS for all routes and origins
CORS(app, resources={r"/api/*": {"origins": "*"}})
metrics = PrometheusMetrics(app)

def get_redis_connection():
    retry_count = 0
    while retry_count < 5:
        try:
            redis_client = redis.Redis(
                host=os.getenv('REDIS_HOST', 'redis'),
                port=int(os.getenv('REDIS_PORT', 6379)),
                socket_connect_timeout=5
            )
            redis_client.ping()
            return redis_client
        except:
            retry_count += 1
            time.sleep(5)
    return None

def get_mongodb_connection():
    retry_count = 0
    while retry_count < 5:
        try:
            mongo_client = pymongo.MongoClient(
                os.getenv('MONGODB_URI', 'mongodb://mongodb:27017/myapp'),
                serverSelectionTimeoutMS=5000
            )
            mongo_client.admin.command('ping')
            return mongo_client
        except:
            retry_count += 1
            time.sleep(5)
    return None

redis_client = get_redis_connection()
mongo_client = get_mongodb_connection()

@app.route('/api/health')
def health():
    return jsonify({
        "status": "healthy",
        "timestamp": time.time()
    })

@app.route('/api/metrics')
def metrics():
    redis_status = False
    mongo_status = False
    
    try:
        if redis_client:
            redis_status = redis_client.ping()
    except:
        pass

    try:
        if mongo_client:
            mongo_status = mongo_client.admin.command('ping')['ok'] == 1.0
    except:
        pass

    return jsonify({
        "redis_connected": redis_status,
        "mongodb_connected": mongo_status,
        "timestamp": time.time()
    })

@app.route('/api/services')
def services():
    return jsonify({
        "services": {
            "frontend": "http://localhost:3000",
            "backend": "http://localhost:5000",
            "prometheus": "http://localhost:9090",
            "grafana": "http://localhost:3001"
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)