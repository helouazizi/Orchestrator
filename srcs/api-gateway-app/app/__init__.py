import time
import socket
from flask import Flask
from .config import Config

def wait_for_services():
    services = [
        (Config.INVENTORY_APP_HOST, Config.INVENTORY_PORT, "Inventory App"),
        (Config.BILLING_APP_HOST, Config.BILLING_PORT, "Billing App"),
        (Config.RABBITMQ_HOST, Config.RABBITMQ_PORT, "RabbitMQ")
    ]

    for host, port, name in services:
        print(f"[*] Waiting for dependency: {name} at {host}:{port}...")
        
        # Infinite retry loop PER service
        while True:
            try:
                with socket.create_connection((host, int(port)), timeout=2):
                    print(f"[✓] {name} is READY!")
                    break  # Exit while loop ONLY when this specific service connects
            except (socket.error, ValueError) as e:
                print(f"[!] {name} not ready yet ({e}). Retrying in 3s...")
                time.sleep(3)

def create_app():
    app = Flask(__name__)

    # Block container boot until ALL 3 dependencies accept connections sequentially
    wait_for_services()

    from .route import services_bp
    app.register_blueprint(services_bp)

    return app