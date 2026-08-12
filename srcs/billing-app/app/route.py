import os
import json
import time
import pika
from dotenv import load_dotenv
from flask import Flask, Blueprint, jsonify
from .models import db, BillingOrder

billing_bp = Blueprint("billing", __name__)

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
            print(f" [!] Malformed JSON message: {body.decode()}")
            ch.basic_nack(method.delivery_tag, requeue=False)
        except Exception as e:
            print(f" [!] Error processing message: {e}")
            db.session.rollback()
            ch.basic_nack(method.delivery_tag, requeue=True)

def start_consuming(app: Flask):
    RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'rabbitmq')
    RABBITMQ_PORT = int(os.getenv('RABBITMQ_PORT', 5672))
    RABBITMQ_USER = os.getenv('RABBITMQ_DEFAULT_USER')
    RABBITMQ_PASS = os.getenv('RABBITMQ_DEFAULT_PASS')
    RABBITMQ_VHOST = os.getenv('RABBITMQ_DEFAULT_VHOST', '/')
    RABBITMQ_QUEUE = os.getenv('RABBITMQ_QUEUE', 'billing_queue')

    credentials = pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
    parameters = pika.ConnectionParameters(
        host=RABBITMQ_HOST,
        port=RABBITMQ_PORT,
        credentials=credentials,
        virtual_host=RABBITMQ_VHOST,
        heartbeat=600
    )

    # Infinite reconnect loop handles transient startup delays (DNS, DB, RabbitMQ boot)
    while True:
        try:
            # 1. Verify DB connection is ready before connecting to RabbitMQ
            with app.app_context():
                db.session.execute(db.text("SELECT 1"))

            # 2. Connect to RabbitMQ
            print(f"Connecting to RabbitMQ at {RABBITMQ_HOST}:{RABBITMQ_PORT}...")
            connection = pika.BlockingConnection(parameters)
            channel = connection.channel()

            channel.queue_declare(
                queue=RABBITMQ_QUEUE,
                durable=True,
                arguments={'x-queue-type': 'quorum'}
            )

            print("Connected! Waiting for messages...")

            on_message_callback = lambda ch, method, properties, body: process_message(
                ch, method, properties, body, app
            )

            channel.basic_consume(
                queue=RABBITMQ_QUEUE,
                on_message_callback=on_message_callback
            )

            # Blocking call: listens for messages continuously
            channel.start_consuming()

        except Exception as e:
            print(f"Consumer disconnected or failed to start: {e}. Retrying in 5s...")
            time.sleep(5)