FROM alpine:3.19

RUN apk add --no-cache python3 py3-pip

WORKDIR /app

# Ensure the log directory exists for the volume mount
RUN mkdir -p /var/log/api-gateway

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

COPY . .

EXPOSE 3000

CMD ["python3", "main.py"]