import os
from flask import Flask, jsonify
from dotenv import load_dotenv
from .models import db
from .routes import movies_bp


load_dotenv()

def create_app():
    app = Flask(__name__)

  
    db_uri = os.getenv('INVENTORY_DATABASE_URL') # Still check for full URL first

    if not db_uri:
        # Construct URI from individual components defined in .env
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

    app.register_blueprint(movies_bp, url_prefix='/api')

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Not found'}), 404

    with app.app_context():
        db.create_all()

    return app