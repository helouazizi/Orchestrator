import pika
import os
import json
from dotenv import load_dotenv
from flask import Flask
# Assuming db and BillingOrder model are defined in app/models.py
from .models import db, BillingOrder

# Load environment variables (if not already loaded by create_app in __init__.py)
# It's good practice to ensure they are loaded here too for robustness.
basedir = os.path.abspath(os.path.dirname(__file__))
dotenv_path = os.path.join(basedir, '../../../.env')
load_dotenv(dotenv_path)

def process_message(ch, method, properties, body, app):
    with app.app_context():
        try:
            order_data = json.loads(body)
            print(f" [x] Received billing order: {order_data}")

            # Save to database
            new_order = BillingOrder(
                user_id=order_data.get('user_id'),
                number_of_items=order_data.get('number_of_items'),
                total_amount=order_data.get('total_amount')
            )
            db.session.add(new_order)
            db.session.commit()
            print(f" [x] Saved order {new_order.id} to database")

            ch.basic_ack(method.delivery_tag)
        except json.JSONDecodeError:
            print(f" [!] Failed to decode JSON from message: {body.decode()}")
            ch.basic_nack(method.delivery_tag, requeue=False) # Don't re-queue malformed messages
        except Exception as e:
            print(f" [!] Error processing message: {e}")
            # Optionally, nack the message if processing failed and you want it re-queued
            ch.basic_nack(method.delivery_tag, requeue=True) # Re-queue for transient errors

def start_consuming(app: Flask):
    RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'rabbit-queue')
    RABBITMQ_PORT = int(os.getenv('RABBITMQ_PORT', 5672))
    RABBITMQ_USER = os.getenv('RABBITMQ_DEFAULT_USER')
    RABBITMQ_PASS = os.getenv('RABBITMQ_DEFAULT_PASS')
    RABBITMQ_VHOST = os.getenv('RABBITMQ_DEFAULT_VHOST', '/')
    RABBITMQ_QUEUE = os.getenv('RABBITMQ_QUEUE', 'billing_queue')

    if not all([RABBITMQ_USER, RABBITMQ_PASS]):
        raise RuntimeError("RabbitMQ credentials (RABBITMQ_DEFAULT_USER, RABBITMQ_DEFAULT_PASS) not set in environment variables.")

    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    parameters = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        virtual_host=RABBITMQ_VHOST,
        heartbeat=600 # Add heartbeat to detect dead connections
    )

    while True: # Loop to attempt reconnection
        try:
            connection = pika.BlockingConnection(parameters)
            channel = connection.channel()
            channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True, arguments={'x-queue-type': 'quorum'})

            print(' [*] Billing consumer waiting for messages. To exit press CTRL+C')

            # Use a lambda to pass the Flask app context to the callback
            on_message_callback = lambda ch, method, properties, body: process_message(ch, method, properties, body, app)
            channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=on_message_callback)
            channel.start_consuming()
        except pika.exceptions.AMQPConnectionError as e:
            print(f" [!] RabbitMQ connection error: {e}. Retrying in 5 seconds...")
            import time
            time.sleep(5)
        except KeyboardInterrupt:
            print(" [x] Billing consumer stopped by user.")
            break
        except Exception as e:
            print(f" [!] An unexpected error occurred in consumer: {e}. Retrying in 5 seconds...")
            import time
            time.sleep(5)