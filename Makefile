# ==============================================================================
# CONFIGURATION & VARIABLES
# ==============================================================================

# Include secret environment variables 
-include .env

# Kubernetes profile and binary wrapper configurations
KUBECONFIG_PATH := $(shell pwd)/k3s-local.yaml
KUBECTL := KUBECONFIG=$(KUBECONFIG_PATH) kubectl

# Target application source microservices directories
SERVICES := srcs/rabbit-queue # srcs/api-gateway-app   srcs/billing-app srcs/inventory-app srcs/inventory-database srcs/billing-database  

# ANSI Color Code Escapes for Terminal Formatting
CLR_CYAN   := \033[36m
CLR_GREEN  := \033[32m
CLR_YELLOW := \033[33m
CLR_RESET  := \033[0m

# ==============================================================================
# ENTRY TARGETS
# ==============================================================================

.PHONY: help init login build push release deploy destroy status run

help: ## Show this automated help dashboard
	@echo "========================================="
	@echo "Microservices DevOps Orchestrator Suite"
	@echo "========================================="
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CLR_CYAN)%-15s$(CLR_RESET) %s\n", $$1, $$2}'
    
init: ## Complete Pipeline: Bootstrap environment, install CLIs, boot cluster, and establish connection

	@echo "$(CLR_CYAN)[1/5] Creating local configuration file environment...$(CLR_RESET)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(CLR_GREEN)STATUS: .env template created successfully.$(CLR_RESET)"; \
	else \
		echo "STATUS: .env file already exists. Skipping copy."; \
	fi
	
	@echo "\n$(CLR_CYAN)[2/5] Verifying native CLI dependency installations...$(CLR_RESET)"
	@chmod +x scripts/install_dependencies.sh
	@bash scripts/install_dependencies.sh
	@chmod +x scripts/install_docker.sh
	@bash scripts/install_docker.sh
	
	@echo "\n$(CLR_CYAN)[3/5] Initializing cloud-native Virtual Machines via Vagrant...$(CLR_RESET)"
	@chmod +x scripts/cluster_up.sh
	@bash scripts/cluster_up.sh
	
	@echo "\n$(CLR_CYAN)[4/5] Establishing cryptographic handshake network bridge...$(CLR_RESET)"
	@chmod +x scripts/connect_host.sh
	@bash scripts/connect_host.sh

	@echo "\n$(CLR_CYAN)[5/5]Linking cluster configuration globally to your system...$(CLR_RESET)"
	@mkdir -p ~/.kube
	@cp k3s-local.yaml ~/.kube/config
	@chmod 600 ~/.kube/config
	@echo "STATUS: Synced cluster config to standard system path (~/.kube/config)"
	@echo "\n========================================================="
	@echo "$(CLR_GREEN)Full Initialization Completed Successfully!$(CLR_RESET)"
	@echo "========================================================="
	@echo "$(CLR_GREEN)Everything is ready to roll for Make targets!$(CLR_RESET)"
	@echo "Check your cluster operational status instantly:"
	@echo "   👉 make status"
	@echo ""
	@echo "$(CLR_YELLOW)ACTION REQUIRED (For Raw CLI Usage):$(CLR_RESET)"
	@echo "To run native 'kubectl' or 'docker' commands outside of Make,"
	@echo "refresh your current terminal window profile once:"
	@echo "   👉 source ~/.zshrc (or ~/.bashrc)"
	@echo "========================================================="

login: ## Securely authenticate with Docker Hub using your secrets
	@echo "Authenticating with Docker Hub..."
	@echo "$(DOCKER_PASS)" | docker login -u "$(DOCKER_USER)" --password-stdin

build: ## Build Docker images for ALL microservices sequentially
	@for service in $(SERVICES); do \
		svc_name=$$(basename $$service); \
		echo "Building Docker Image for [$$svc_name]..."; \
		docker build -t $(DOCKER_USER)/$$svc_name:latest ./$$service; \
	done
run:
	docker run 938a817bb966 -t mq-test

push: login ## Push ALL built microservices images to Docker Hub
	@for service in $(SERVICES); do \
		svc_name=$$(basename $$service); \
		echo "Pushing Image [$$svc_name] to Docker Hub..."; \
		docker push $(DOCKER_USER)/$$svc_name:latest; \
	done

release: build push ## Pipeline: Build and Push all services in one command
deploy: ## Apply ALL manifest configuration files with targeted variable injection

	@echo "Deploying all manifests to K3s cluster..."
	$(foreach v,$(shell sed 's/=.*//' .env),$(eval export $(v)))
	@FILES=$$(find manifests -maxdepth 1 -name "*.yaml" -o -name "*.yml" 2>/dev/null); \
	if [ -z "$$FILES" ]; then \
		echo "⚠️ ERROR: No .yaml or .yml files found inside the 'manifests/' folder!"; \
		exit 1; \
	fi; \
	for file in $$FILES; do \
		echo "$(CLR_CYAN)Processing $$file...$(CLR_RESET)"; \
		REQUIRED_VARS=$$(grep -o '\$$[A-Z0-9_]*' $$file | sort -u | tr -d '$$' | awk '{print "$$"$$1}' | tr '\n' ','); \
		envsubst "$$REQUIRED_VARS" < $$file | $(KUBECTL) apply -f -; \
	done

debug-injection: ## Preview exactly what text envsubst passes to the cluster
	$(foreach v,$(shell sed 's/=.*//' .env),$(eval export $(v)))
	@for file in $$(find manifests -maxdepth 1 -name "*.yaml" 2>/dev/null); do \
		echo "📁 File: $$file"; \
		RAW_VARS=$$(grep -o '\$$[A-Z0-9_]*' $$file | sort -u | tr -d '$$'); \
		if [ -z "$$RAW_VARS" ]; then \
			echo "   ↳ ℹ️  No environment variables found in this manifest."; \
		else \
			echo "   ↳ Injected Variables:"; \
			for var in $$RAW_VARS; do \
				VALUE=$$(eval echo "\$$$$var"); \
				if [ -n "$$VALUE" ]; then \
					echo "     🔹 \$$$$var ➔ $$VALUE"; \
				else \
					echo "     ⚠️  \$$$$var ➔ NOT FOUND IN .ENV"; \
				fi; \
			done; \
		fi; \
		echo "------------------------------------------------\n"; \
	done



destroy: ## Tear down ALL deployed infrastructure resources, containers, and VMs
	@echo "$(CLR_CYAN)[1/3] Gracefully terminating Kubernetes manifest deployments...$(CLR_RESET)"
	@-$(KUBECTL) delete -f manifests/ 2>/dev/null || true

	@echo "\n$(CLR_CYAN)[2/4] Purging localized rootless Docker runtime resources...$(CLR_RESET)"
	@-docker system prune -a --volumes -f 2>/dev/null || true
	@echo "$(CLR_GREEN)STATUS: Docker image cache, dangling volumes, and stopped containers cleared.$(CLR_RESET)"

	@echo "\n$(CLR_CYAN)[3/4] Destroying cloud-native Vagrant Virtual Machine nodes...$(CLR_RESET)"
	@vagrant destroy -f
	
	@echo "\n$(CLR_CYAN)[4/4]Removing temporary local configurations...$(CLR_RESET)"
	@rm -f k3s-local.yaml
	
	@echo "========================================================="
	@echo "$(CLR_GREEN)💥 Environment Completely Obliterated Successfully!$(CLR_RESET)"
	@echo "========================================================="


status: ## Check the complete multi-node cluster configuration state

	@echo "$(CLR_CYAN)SYSTEM: Checking Cluster Nodes...$(CLR_RESET)"
	@$(KUBECTL) get nodes -o wide
	@echo "\n$(CLR_CYAN)SYSTEM: Monitoring Running Pods...$(CLR_RESET)"
	@$(KUBECTL) get pods -o wide -A
	@echo "\n$(CLR_CYAN)SYSTEM: Monitoring Routing Services...$(CLR_RESET)"
	@$(KUBECTL) get svc -A

port-forward: ## Establish active port-forward tunnel to the API Gateway local interface
	@echo "$(CLR_CYAN)Opening secure port-forward tunnel to API Gateway (Ctrl+C to stop)...$(CLR_RESET)"
	@kubectl port-forward service/api-gateway-service 3000:3000