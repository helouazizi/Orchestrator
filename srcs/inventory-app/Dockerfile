FROM alpine:3.19

# Install Python and build dependencies for PostgreSQL (psycopg2)
RUN apk add --no-cache python3 py3-pip postgresql-dev gcc python3-dev musl-dev

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages

COPY . .

EXPOSE 8080

CMD ["python3", "main.py"]