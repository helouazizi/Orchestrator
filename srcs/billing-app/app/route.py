import pika
import os
import json
from dotenv import load_dotenv
from flask import Flask, Blueprint, jsonify
# Assuming db and BillingOrder model are defined in app/models.py
from .models import db, BillingOrder


billing_bp = Blueprint("billing", __name__)

# Load environment variables (if not already loaded by create_app in __init__.py)
# It's good practice to ensure they are loaded here too for robustness.
basedir = os.path.abspath(os.path.dirname(__file__))
dotenv_path = os.path.join(basedir, '../../../.env')
load_dotenv(dotenv_path)

@billing_bp.route("/billing", methods=["GET"])
def get_billing_orders():
    orders = BillingOrder.query.order_by(BillingOrder.id.desc()).all()

    return jsonify([
        {
            "id": order.id,
            "user_id": order.user_id,
            "number_of_items": order.number_of_items,
            "total_amount": order.total_amount,
        }
        for order in orders
    ]), 200

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

    print("========== BILLING CONSUMER ==========")
    print(f"HOST  : {RABBITMQ_HOST}")
    print(f"PORT  : {RABBITMQ_PORT}")
    print(f"USER  : {RABBITMQ_USER}")
    print(f"VHOST : {RABBITMQ_VHOST}")
    print(f"PASS : {RABBITMQ_PASS}")
    print(f"QUEUE : {RABBITMQ_QUEUE}")
    print("======================================")

    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)

    parameters = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        virtual_host=RABBITMQ_VHOST,
        heartbeat=600
    )

    while True:
        try:
            print("STEP 1 - Connecting...")
            connection = pika.BlockingConnection(parameters)

            print("STEP 2 - Connected")

            channel = connection.channel()
            print("STEP 3 - Channel created")

            channel.queue_declare(
                queue=RABBITMQ_QUEUE,
                durable=True,
                arguments={"x-queue-type": "quorum"}
            )
            print("STEP 4 - Queue declared")

            on_message_callback = lambda ch, method, properties, body: process_message(
                ch, method, properties, body, app
            )

            channel.basic_consume(
                queue=RABBITMQ_QUEUE,
                on_message_callback=on_message_callback,
                auto_ack=False
            )
            print("STEP 5 - Consumer registered")

            print("STEP 6 - Starting consume")
            channel.start_consuming()

            print("STEP 7 - Returned from consuming")

        except Exception as e:
            import traceback

            print("=" * 80)
            print("EXCEPTION")
            print(type(e))
            print(repr(e))
            traceback.print_exc()
            print("=" * 80)

            time.sleep(5)