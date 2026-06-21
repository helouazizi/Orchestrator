# 🚀 play-with-containers

---

## 📖 Overview

This project introduces **containerization concepts** and provides hands-on experience by building a **microservices architecture** using Docker and Docker Compose.  

You will deploy multiple services, connect them through networks and volumes, and ensure they run reliably in isolated containers. The project also emphasizes best practices for building Docker images and orchestrating multi-container applications.

---

# ⚙️ Instructions

This project is a continuation of the project [CRUD-MASTER](https://github.com/ismailsayen/CRUD-Master), but this time we will use **Docker** instead of **Vagrant**.

> ⚠️ Before starting, make sure you have Docker installed on your machine.

---

## 🏗️ Architecture

You have to implement this architecture:

![image](https://learn.zone01oujda.ma//api/content/root/01-edu_module/content/play-with-containers/resources/play-with-containers-py.png)

---

# 📦 Project Services

**Play-with-containers** is a microservices project consisting of:

- `api-gateway`
- `billing-app`
- `inventory-app`
- `RabbitMQ`
- `PostgreSQL databases`

To ensure optimal container performance, each service, server, and database runs on its own dedicated image and container.

---

## 🗄️ Database Containers

### 🐘 `inventory-db`

| Property | Value |
|----------|--------|
| **Type** | PostgreSQL Database Server |
| **Purpose** | Stores the inventory database |
| **Port** | `5432` |

---

### 🐘 `billing-db`

| Property | Value |
|----------|--------|
| **Type** | PostgreSQL Database Server |
| **Purpose** | Stores the billing database |
| **Port** | `5432` |

---

## 🖥️ Application Containers

### 📦 `inventory-app`

| Property | Value |
|----------|--------|
| **Type** | Backend Service |
| **Connected To** | `inventory-db` |
| **Accessible Port** | `8080` |

---

### 💳 `billing-app`

| Property | Value |
|----------|--------|
| **Type** | Backend Service |
| **Connected To** | `billing-db` |
| **Consumes** | Messages from RabbitMQ queue |
| **Accessible Port** | `8080` |

---

## 📨 Messaging Container

### 🐇 `rabbit-queue`

| Property | Value |
|----------|--------|
| **Type** | RabbitMQ Server |
| **Purpose** | Handles message queueing between services |

---

## 🌐 API Gateway

### 🚪 `api-gateway-app`

| Property | Value |
|----------|--------|
| **Type** | API Gateway Server |
| **Purpose** | Forwards requests to other services |
| **Accessible Port** | `3000` |

---

---

# 💾 Docker Volumes

Docker volumes are used to persist data outside the lifecycle of containers.

---

## 🗄️ Database Volumes

### 🐘 `inventory-db` Volume

| Property | Value |
|----------|--------|
| **Purpose** | Stores the inventory database data |
| **Persistence** | Keeps data even if the container is removed |

---

### 🐘 `billing-db` Volume

| Property | Value |
|----------|--------|
| **Purpose** | Stores the billing database data |
| **Persistence** | Keeps data even if the container is removed |

---

## 📜 Logging Volume

### 🚪 `api-gateway-app` Volume

| Property | Value |
|----------|--------|
| **Purpose** | Stores API gateway logs |
| **Usage** | Helps with monitoring and debugging |

---

# 🌐 Docker Network

You must create a dedicated **Docker network** that establishes communication between all services inside your Docker host.

---

## 🔗 Network Requirements

| Requirement | Description |
|-------------|-------------|
| **Internal Communication** | All containers must communicate through the same Docker network |
| **Isolation** | Services should only communicate internally unless explicitly exposed |
| **External Access** | Only the `api-gateway-app` must be accessible from outside |
| **Exposed Port** | `3000` |

---

## 🚨 Important Note

> Any external request must be able to access **only** the `api-gateway-app` via port `3000`.

All other services and databases must remain internal to the Docker network.

---

# 📚 Resources

Here are some useful resources to better understand Docker, Docker Compose, networking, and volumes.

---

## 🐳 Docker Documentation

| Resource | Link |
|----------|------|
| Docker Compose Documentation | https://dev.to/alexmercedcoder/a-deep-dive-into-docker-compose-27h5 |
| Docker Networking | https://docs.docker.com/network/ |
| Docker Volumes | https://docs.docker.com/storage/volumes/ |
| Docker architecture  | https://agenda.infn.it/event/32136/sessions/23644/attachments/95750/131779/docker%20-%20architecture.pdf |
