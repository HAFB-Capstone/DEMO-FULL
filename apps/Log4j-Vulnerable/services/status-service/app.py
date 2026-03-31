"""
HAFB Status Service
NOT vulnerable to Log4Shell — uses Python logging, not Log4j.

This service exists to demonstrate that not all services in an environment
are vulnerable. Blue team must use SBOMs to identify which services
actually use Log4j.
"""
import logging
import os
from flask import Flask, jsonify

app = Flask(__name__)

# Standard Python logging — NOT Log4j, NOT vulnerable
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.route("/")
def index():
    return jsonify({
        "service": "HAFB Status Service",
        "status": "running",
        "version": "1.0.0",
        "language": "Python",
        "logging": "Python standard library — NOT Log4j"
    })


@app.route("/health")
def health():
    return jsonify({"status": "UP"})


@app.route("/status")
def status():
    logger.info("Status check requested")
    return jsonify({
        "services": {
            "auth-service": "http://auth-service:8001",
            "inventory-service": "http://inventory-service:8002",
            "status-service": "http://status-service:8003"
        },
        "environment": "HAFB Training Lab",
        "note": "This service uses Python logging — not vulnerable to Log4Shell"
    })


@app.route("/search")
def search():
    from flask import request
    q = request.args.get("q", "")
    # Python logging — safe, no JNDI processing
    logger.info(f"Status search: {q}")
    return jsonify({
        "query": q,
        "message": "This service is not vulnerable to Log4Shell",
        "logging_library": "Python standard logging"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8003)