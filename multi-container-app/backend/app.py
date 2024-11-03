from flask import Flask, jsonify
from flask_cors import CORS
from prometheus_flask_exporter import PrometheusMetrics
import redis
import pymongo
import os

app = Flask(__name__)
CORS(app)
metrics = PrometheusMetrics(app)

# Redis connection
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'redis'),
    port=int(os.getenv('REDIS_PORT', 6379))
)

# MongoDB connection
mongo_client = pymongo.MongoClient(os.getenv('MONGODB_URI', 'mongodb://mongodb:27017/myapp'))
db = mongo_client.myapp

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/api/metrics')
def metrics():
    return jsonify({
        "redis_connected": redis_client.ping(),
        "mongodb_connected": mongo_client.admin.command('ping')['ok'] == 1.0
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)