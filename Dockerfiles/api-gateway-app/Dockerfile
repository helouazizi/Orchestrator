FROM alpine:latest

RUN apk add --no-cache \
    bash \
    python3 \
    py3-pip

WORKDIR /api-gateway-app

COPY requirements.txt .

RUN pip3 install --break-system-packages --no-cache-dir -r requirements.txt 

COPY . .

CMD ["python3","server.py"]

