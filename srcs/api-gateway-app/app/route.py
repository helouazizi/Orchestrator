from flask import request,Response,jsonify,Blueprint
from .config import Config
import requests
import pika

services_bp= Blueprint("services_bp",__name__)

def proxy_request(url:str):
    try:
        headers = {}
        for key, value in request.headers:
            if key != "Host":
                headers[key] = value        
        resp=requests.request(
            method=request.method,
            url=url,
            headers=headers,
            params=request.args,
            data=request.data,
            cookies=request.cookies,
            allow_redirects=False
        )
        response = Response(resp.content, resp.status_code)
        for key, value in resp.headers.items():
            response.headers[key] = value

        return response
    except requests.exceptions.ConnectionError :
        return  jsonify({"message":"CONNECTION REFUSED"}),503
    
def billing_service(path):
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
        print("========== RabbitMQ Debug ==========")
        print(f"Host      : {Config.RABBITMQ_HOST}")
        print(f"Port      : {Config.RABBITMQ_PORT}")
        print(f"User      : {Config.RABBITMQ_DEFAULT_USER}")
        print(f"VHost     : {Config.RABBITMQ_DEFAULT_VHOST}")
        print(f"Queue     : {Config.RABBITMQ_QUEUE}")
        print("Resolving host...")

        import socket

        try:
            ip = socket.gethostbyname(Config.RABBITMQ_HOST)
            print(f"Resolved IP: {ip}")
        except Exception as e:
            print(f"DNS Resolution FAILED: {e}")
            raise

        credential = pika.PlainCredentials(
            Config.RABBITMQ_DEFAULT_USER,
            Config.RABBITMQ_DEFAULT_PASS
        )

        params = pika.ConnectionParameters(
            host=Config.RABBITMQ_HOST,
            port=int(Config.RABBITMQ_PORT),
            credentials=credential,
            virtual_host=Config.RABBITMQ_DEFAULT_VHOST
        )

        print("Opening RabbitMQ connection...")
        connection = pika.BlockingConnection(params)
        print("Connection established.")

        channel = connection.channel()
        print("Channel created.")

        channel.queue_declare(
            queue=Config.RABBITMQ_QUEUE,
            durable=True,
            arguments={"x-queue-type": "quorum"}
        )
        print("Queue declared.")

        channel.basic_publish(
            exchange="",
            routing_key=Config.RABBITMQ_QUEUE,
            body=request.get_data()
        )
        print("Message published.")

        connection.close()
        print("Connection closed.")
        print("====================================")

        return jsonify({"message": "message added to queue successfully"}), 200

    except Exception as e:
        import traceback

        print("========== RabbitMQ ERROR ==========")
        traceback.print_exc()
        print("====================================")

        return jsonify({
            "error": f"Could not queue billing request: {str(e)}"
        }), 503   
    
@services_bp.route("/<path:path>",methods=["GET","POST","DELETE","PUT"])
def server(path:str):
    if path.startswith("api/movies"):
        print(f"DEBUG: Forwarding request to: http://{Config.INVENTORY_APP_HOST}:{Config.INVENTORY_PORT}/{path}")
        return proxy_request(f"http://{Config.INVENTORY_APP_HOST}:{Config.INVENTORY_PORT}/{path}")
    elif path.startswith("api/billing"):
        if request.method == "GET":
            return proxy_request(
                f"http://{Config.BILLING_APP_HOST}:{Config.BILLING_PORT}/{path}"
            )
        print(f"DEBUG: Forwarding request to: http://{Config.BILLING_APP_HOST}:{Config.BILLING_PORT}/{path}")
        return billing_service(path)
    else:
        return jsonify({"message":"SERVICE NOT FOUND"}), 404     
    
@services_bp.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "UP"
    }), 200