# Include your secret credentials automatically
-include .env

# Set Kubernetes profile path
KUBECONFIG_PATH := $(shell pwd)/k3s-local.yaml
KUBECTL := KUBECONFIG=$(KUBECONFIG_PATH) kubectl

# List your microservices folders relative to the root
SERVICES := srcs/api-gateway-app srcs/billing-app srcs/inventory-app srcs/postgres-image srcs/rabbit-queue

.PHONY: help init login build push release deploy destroy status

help: ## Show this automated help dashboard
	@echo "🤖 Microservices DevOps Orchestrator Suite"
	@echo "========================================="
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	
init: ## Create the .env file from the .env.example template
	@echo "🤖 Creating .env file..."
	@cp .env.example .env

login: ## Securely authenticate with Docker Hub using your secrets
	@echo "🔑 Authenticating with Docker Hub..."
	@echo "$(DOCKER_PASS)" | docker login -u "$(DOCKER_USER)" --password-stdin

build: ## Build Docker images for ALL microservices sequentially
	@for service in $(SERVICES); do \
		svc_name=$$(basename $$service); \
		echo "🏗️ Building Docker Image for [$$svc_name]..."; \
		docker build -t $(DOCKER_USER)/$$svc_name:latest ./$$service; \
	done

push: login ## Push ALL built microservices images to Docker Hub
	@for service in $(SERVICES); do \
		svc_name=$$(basename $$service); \
		echo "🚀 Pushing [$$svc_name] to Docker Hub..."; \
		docker push $(DOCKER_USER)/$$svc_name:latest; \
	done

release: build push ## Pipeline: Build and Push all services in one command

deploy: ## Apply ALL manifest configuration files at once
	@echo "🚀 Deploying all manifests to K3s cluster..."
	$(KUBECTL) apply -f manifests/

destroy: ## Tear down ALL deployed infrastructure resources
	@echo "🧹 Cleaning up K3s resources..."
	$(KUBECTL) delete -f manifests/

status: ## Check the complete multi-node cluster configuration state
	@echo "🌐 Checking Cluster Nodes..."
	@$(KUBECTL) get nodes -o wide
	@echo "\n📦 Monitoring Running Pods..."
	@$(KUBECTL) get pods -o wide -A
	@echo "\n🔌 Monitoring Routing Services..."
	@$(KUBECTL) get svc -A