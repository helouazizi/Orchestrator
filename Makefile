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
	
init: ## Complete Pipeline: Bootstrap environment, install CLIs, boot cluster, and establish connection
	@echo "🤖 [1/4] Creating local configuration file environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ .env template created successfully."; \
	else \
		echo "ℹ️ .env file already exists. Skipping copy."; \
	fi
	
	@echo "\n⚙️ [2/4] Verifying native CLI dependency installations..."
	@chmod +x scripts/install_dependencies.sh
	@bash scripts/install_dependencies.sh
	
	@echo "\n🚀 [3/4] Initializing cloud-native Virtual Machines via Vagrant..."
	@chmod +x scripts/cluster_up.sh
	@bash scripts/cluster_up.sh
	
	@echo "\n🔌 [4/4] Establishing cryptographic handshake network bridge..."
	@chmod +x scripts/connect_host.sh
	@bash scripts/connect_host.sh
	
	@echo "\n========================================================="
	@echo "🎉  Full Initialization Completed Successfully!"
	@echo "========================================================="

	@echo "👉 Befor  connect execute this comand 'export KUBECONFIG=\$(pwd)/k3s-local.yaml'"
	@echo "👉 And refrech your terminal session"
	@echo "👉 To see check do 'make status'"

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