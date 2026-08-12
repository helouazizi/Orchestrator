import os
import time
from flask import Flask, jsonify
from dotenv import load_dotenv
from sqlalchemy.exc import OperationalError
from .models import db
from .routes import movies_bp

load_dotenv()

def init_db_with_retries(app, max_retries=10, delay=3):
    with app.app_context():
        for attempt in range(1, max_retries + 1):
            try:
                print(f"[Attempt {attempt}/{max_retries}] Connecting to inventory database...")
                # Test the connection directly
                db.session.execute(db.text("SELECT 1"))
                
                # Create tables if needed
                db.create_all()
                print("Database connection established and tables verified successfully.")
                return
            except OperationalError as e:
                print(f"Database connection failed: {e}")
                if attempt == max_retries:
                    print("Max retries reached. Could not connect to inventory database.")
                    raise e
                print(f"Retrying in {delay} seconds...")
                time.sleep(delay)

def create_app():
    app = Flask(__name__)

    db_uri = os.getenv('INVENTORY_DATABASE_URL')

    if not db_uri:
        user = os.getenv('POSTGRES_USER_INVENTORY')
        password = os.getenv('POSTGRES_PASSWORD_INVENTORY')
        host = os.getenv('INVENTORY_DB_HOST', 'inventory-db')
        db_name = os.getenv('POSTGRES_DB_INVENTORY')
        port = os.getenv('INVENTORY_DB_PORT', '5432')

        if all([user, password, db_name]):
            db_uri = f"postgresql://{user}:{password}@{host}:{port}/{db_name}"

    if not db_uri:
        raise RuntimeError("Database configuration is missing. Set INVENTORY_DATABASE_URL or individual POSTGRES_... vars.")

    app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)

    # Retry loop before allowing the app server to start receiving requests
    init_db_with_retries(app)

    app.register_blueprint(movies_bp, url_prefix='/api')

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Not found'}), 404

    return app