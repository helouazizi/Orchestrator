import time
import pika
import requests
from flask import request, Response, jsonify, Blueprint
from .config import Config

services_bp = Blueprint("services_bp", __name__)

def proxy_request(url: str, retries: int = 3, delay: float = 1.0):
    headers = {k: v for k, v in request.headers if k.lower() != "host"}

    for attempt in range(1, retries + 1):
        try:
            resp = requests.request(
                method=request.method,
                url=url,
                headers=headers,
                params=request.args,
                data=request.get_data(),
                cookies=request.cookies,
                allow_redirects=False,
                timeout=5
            )
            response = Response(resp.content, resp.status_code)
            for k, v in resp.headers.items():
                response.headers[k] = v
            return response

        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as e:
            print(f"Proxy attempt {attempt}/{retries} failed for {url}: {e}")
            if attempt == retries:
                return jsonify({"message": "SERVICE UNAVAILABLE"}), 503
            time.sleep(delay)

def publish_to_rabbitmq(body: bytes, retries: int = 3, delay: float = 1.0):
    credentials = pika.PlainCredentials(
        Config.RABBITMQ_DEFAULT_USER,
        Config.RABBITMQ_DEFAULT_PASS
    )
    params = pika.ConnectionParameters(
        host=Config.RABBITMQ_HOST,
        port=int(Config.RABBITMQ_PORT),
        credentials=credentials,
        virtual_host=Config.RABBITMQ_DEFAULT_VHOST
    )

    for attempt in range(1, retries + 1):
        try:
            connection = pika.BlockingConnection(params)
            channel = connection.channel()

            channel.queue_declare(
                queue=Config.RABBITMQ_QUEUE,
                durable=True,
                arguments={"x-queue-type": "quorum"}
            )

            channel.basic_publish(
                exchange="",
                routing_key=Config.RABBITMQ_QUEUE,
                body=body
            )
            connection.close()
            return True

        except Exception as e:
            print(f"RabbitMQ publish attempt {attempt}/{retries} failed: {e}")
            if attempt == retries:
                raise e
            time.sleep(delay)

def billing_service(path: str):
    if request.method == "GET":
        target_url = f"http://{Config.BILLING_APP_HOST}:{Config.BILLING_PORT}/{path}"
        return proxy_request(target_url)

    data = request.get_json()
    if not data:
        return jsonify({"message": "Request Body is required."}), 400

    required_fields = ["user_id", "number_of_items", "total_amount"]
    for field in required_fields:
        if field not in data:
            return jsonify({"message": f"{field} is required."}), 400

    try:
        publish_to_rabbitmq(request.get_data())
        return jsonify({"message": "message added to queue successfully"}), 200
    except Exception as e:
        return jsonify({"error": f"Could not queue billing request: {str(e)}"}), 503

@services_bp.route("/<path:path>", methods=["GET", "POST", "DELETE", "PUT"])
def server(path: str):
    if path.startswith("api/movies"):
        target_url = f"http://{Config.INVENTORY_APP_HOST}:{Config.INVENTORY_PORT}/{path}"
        return proxy_request(target_url)

    elif path.startswith("api/billing"):
        return billing_service(path)

    return jsonify({"message": "SERVICE NOT FOUND"}), 404

@services_bp.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "UP"}), 200