import os
from dotenv import load_dotenv

# Load environment variables from the shared .env file at the project root
# Assuming config.py is in app/ and .env is in the project root
basedir = os.path.abspath(os.path.dirname(__file__))
dotenv_path = os.path.join(basedir, '../../../.env')
load_dotenv(dotenv_path)

class Config:
    # Application Hosts and Ports
    INVENTORY_APP_HOST = os.getenv('INVENTORY_APP_HOST', 'inventory-app')
    INVENTORY_PORT = os.getenv('INVENTORY_PORT', '8080')
    BILLING_APP_HOST = os.getenv('BILLING_APP_HOST', 'billing-app')
    BILLING_PORT = os.getenv('BILLING_PORT', '8080')
    API_GATEWAY_PORT = os.getenv('API_GATEWAY_PORT', '3000')

    # RabbitMQ Configuration
    RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'rabbit-queue')
    RABBITMQ_PORT = os.getenv('RABBITMQ_PORT', '5672')
    RABBITMQ_DEFAULT_USER = os.getenv('RABBITMQ_DEFAULT_USER')
    RABBITMQ_DEFAULT_PASS = os.getenv('RABBITMQ_DEFAULT_PASS')
    RABBITMQ_DEFAULT_VHOST = os.getenv('RABBITMQ_DEFAULT_VHOST', '/')
    RABBITMQ_QUEUE = os.getenv('RABBITMQ_QUEUE', 'billing_queue')

    # Ensure critical RabbitMQ credentials are set
    if not all([RABBITMQ_DEFAULT_USER, RABBITMQ_DEFAULT_PASS]):
        raise RuntimeError("RabbitMQ credentials (RABBITMQ_DEFAULT_USER, RABBITMQ_DEFAULT_PASS) must be set in .env")