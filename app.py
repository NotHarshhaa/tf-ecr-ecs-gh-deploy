"""Flask-based application with health check and hostname response."""

import socket
import logging
import os
from flask import Flask, jsonify

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")


def create_app():
    """Create a Flask application."""
    app = Flask(__name__)

    @app.route('/health', methods=['GET'])
    def health_check():
        """Health check endpoint."""
        return jsonify(message="Flask is operational", error=False), 200

    @app.route('/', methods=['GET'])
    def index():
        """Main index route that returns the hostname."""
        hostname = socket.gethostname()
        logging.info(f"Request received from {hostname}")
        return jsonify(message=f"Hello from {hostname}"), 200

    @app.errorhandler(404)
    def not_found(error):
        """Handle 404 errors."""
        return jsonify(error=True, message="Resource not found"), 404

    @app.errorhandler(500)
    def internal_error(error):
        """Handle internal server errors."""
        logging.error(f"Internal Server Error: {error}")
        return jsonify(error=True, message="Internal Server Error"), 500

    return app


def main():
    """Main entry point."""
    app = create_app()

    # Read port from environment variable or default to 80
    port = int(os.getenv("APP_PORT", 80))
    debug_mode = os.getenv("FLASK_DEBUG", "False").lower() in ["true", "1"]

    logging.info(f"Starting Flask app on 0.0.0.0:{port}, Debug={debug_mode}")
    app.run(debug=debug_mode, host="0.0.0.0", port=port)


if __name__ == "__main__":
    main()
