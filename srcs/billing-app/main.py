from app import create_app
from app.route import start_consuming
import threading
import os

app = create_app()

if __name__ == "__main__":
    # Start the RabbitMQ consumer in a background thread so the 
    # Flask web server can run simultaneously on port 8080.
    consumer_thread = threading.Thread(target=start_consuming, args=(app,), daemon=True)
    consumer_thread.start()

    port = int(os.environ.get('BILLING_PORT', 8080))
    app.run(host="0.0.0.0", port=port)