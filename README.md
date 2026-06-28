# Orchestrator

## Project Overview

This project demonstrates Kubernetes orchestration of a microservices stack in a local K3s cluster managed with Vagrant. It focuses on deploying and operating services through Kubernetes manifests, not on Dockerfile authoring.

The architecture includes:

- an API gateway (`api-gateway-app`),
- two backend services (`inventory-app` and `billing-app`),
- two persistent databases (`inventory-db` and `billing-db`),
- a RabbitMQ messaging service (`rabbit-queue`).

The main goals are container orchestration, workload resiliency with StatefulSets, horizontal scaling using HPA, and secure secret management.

## Learning Objectives

By completing this project, you will be able to:

- Deploy microservices and databases in a K3s cluster using Kubernetes manifests.
- Configure horizontal scaling and StatefulSets for resilient and efficient workloads.
- Manage secrets and credentials securely in Kubernetes.
- Use container images in manifests while keeping orchestration as the main focus.
- Document and justify your cluster architecture and deployment choices.

## Architecture Summary

The required deployment consists of the following components:

- `inventory-db`: PostgreSQL database server for inventory data, accessible on port `5432`.
- `billing-db`: PostgreSQL database server for billing data, accessible on port `5432`.
- `inventory-app`: application server connected to `inventory-db`, accessible on port `8080`.
- `billing-app`: application server connected to `billing-db`, consuming RabbitMQ messages, accessible on port `8080`.
- `rabbit-queue`: RabbitMQ message broker.
- `api-gateway-app`: API gateway forwarding requests to other services, accessible on port `3000`.

## Cluster Topology

The K3s cluster is built using Vagrant with two virtual machines:

1. `Master`: K3s control plane node.
2. `Agent`: K3s worker node.

Both nodes must be connected and available before applying manifests.

## Orchestration Script

This project includes `orchestrator.sh` to manage the Vagrant cluster lifecycle:

```bash
./orchestrator.sh create
# cluster created

./orchestrator.sh start
# cluster started

./orchestrator.sh stop
# cluster stopped

./orchestrator.sh destroy
# cluster destroyed
```

## Kubernetes Resource Guidelines

- Use one manifest file per component or resource.
- Deploy `api-gateway-app` and `inventory-app` as `Deployment` resources.
- Configure `HorizontalPodAutoscaler` for both apps with:
  - minimum replicas: `1`
  - maximum replicas: `3`
  - CPU target utilization: `60%`
- Deploy `billing-app` as a `StatefulSet`.
- Deploy `inventory-db` and `billing-db` as `StatefulSet` resources.
- Use persistent volumes so database data survives pod restarts and node movement.
- Store passwords and credentials in Kubernetes `Secret` resources only.
- Do not put credentials directly inside deployment manifests.

## Container Image Management

The main focus of this project is Kubernetes orchestration in a K3s cluster. The Kubernetes manifests reference container images hosted on Docker Hub, but the orchestration of those containers is the core concern.

Example manifest reference:

```yaml
image: <dockerhub-username>/api-gateway-app:v1.0
```

## Testing and Stress Validation

To validate the deployment and observe Kubernetes autoscaling, follow these steps:

### 1. Verify cluster health

```bash
./connection.sh
kube get nodes
kube get all -A
kube get hpa -A
```

Expected output should show both the master and agent nodes in `Ready` state.

### 2. Confirm application resources

```bash
kube get deployments,statefulsets,services,secrets -A
kube describe hpa api-gateway-hpa
kube describe hpa inventory-app-hpa
```

### 3. Run a load test against the API gateway


Example using your preferred shell stress loop:

```bash
while true; do
    for i in {1..10}; do
        curl --silent --output /dev/null \
            --location 'http://192.168.56.10:30000/api/movies' \
            --header 'Content-Type: application/json' \
            --data '{
                "title": "titanic",
                "description": "titanic description ..."
            }' &
    done
    wait
done
```

Example using a temporary Kubernetes pod:

```bash
kube run load-generator --rm -it --image=alpine/siege -- /bin/sh -c "apk add --no-cache curl && siege -c20 -t60S http://api-gateway-service:3000/"
```

### 4. Monitor autoscaling behavior

While the load test runs, watch the HPA and pod count:

```bash
kubectl get hpa api-gateway-hpa inventory-app-hpa -w
kubectl get pods -l app=api-gateway -w
kubectl get pods -l app=invapp -w
```

You should see replica counts increase when CPU consumption exceeds the 60% threshold.

### 5. Inspect pod metrics

If metrics-server is installed, use:

```bash
kubectl top pods -A
```

This confirms Kubernetes receives CPU usage metrics and can trigger scaling.

### 6. Verify stateful services remain stable

Check that database pods stay available and retain data after restarts:

```bash
kubectl get statefulsets -A
kubectl rollout restart statefulset inventory-database
kubectl rollout restart statefulset billing-database
kubectl get pods -l app=inventoryDB
kubectl get pods -l app=billingDB
```

## Load and Traffic Testing Best Practices

- Start with a moderate number of concurrent requests and increase gradually.
- Target the API gateway to generate real service traffic through the cluster.
- Monitor `kubectl get pods`, `kubectl get hpa`, and `kubectl top pods` while load is active.
- Use nodes and service endpoints, not only pod IPs, to confirm external access.
- Validate that the billing app and message queue remain healthy as traffic grows.

## Secure Handling of Credentials

- Store database credentials, RabbitMQ credentials, and any API keys as Kubernetes Secrets.
- Reference secrets from pod environment variables using `valueFrom.secretKeyRef`.
- Keep manifest files free of plaintext credentials.

## Summary

This repository is designed to teach a complete K3s Kubernetes deployment for a microservices stack using:

- Vagrant for cluster provisioning,
- Docker Hub for image distribution,
- Kubernetes manifests for each component,
- StatefulSets for persistent database workloads,
- HPA for CPU-based scaling,
- Secure secret management.

Testing the environment with simulated traffic shows how Kubernetes automatically adds pods under load and maintains resilient service delivery.

**Maintainer**: [Ismail Sayen](https://github.com/ismailsayen), [Hassan El ouaziz](https://github.com/helouazizi) 
