import os
from flask import Flask, jsonify
from dotenv import load_dotenv
from .models import db # Assuming a models.py exists for BillingOrder model

# Load environment variables from the shared .env file at the project root
# Assuming __init__.py is in app/ and .env is in the project root
basedir = os.path.abspath(os.path.dirname(__file__))
dotenv_path = os.path.join(basedir, '../../../.env')
load_dotenv(dotenv_path)

def create_app():
    app = Flask(__name__)

    db_uri = os.getenv('BILLING_DATABASE_URL') # Check for full URL first

    if not db_uri:
        # Construct URI from individual components defined in .env
        user = os.getenv('POSTGRES_USER_BILLING')
        password = os.getenv('POSTGRES_PASSWORD_BILLING')
        host = os.getenv('BILLING_DB_HOST', 'billing-db')
        db_name = os.getenv('POSTGRES_DB_BILLING')
        port = os.getenv('BILLING_DB_PORT', '5432')

        if all([user, password, db_name]):
            db_uri = f"postgresql://{user}:{password}@{host}:{port}/{db_name}"

    if not db_uri:
        raise RuntimeError("Billing Database configuration is missing. Set BILLING_DATABASE_URL or individual POSTGRES_... vars.")

    app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Not found'}), 404

    with app.app_context():
        db.create_all() # Create tables if they don't exist

    return app