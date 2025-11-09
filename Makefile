.PHONY: help deploy destroy validate test clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

validate: ## Validate all configurations
	@echo "🔍 Validating Terraform..."
	@terraform fmt -check -recursive terraform/
	@echo "🔍 Validating Kubernetes manifests..."
	@find k8s/ -name '*.yaml' -exec kubeval {} \;
	@echo "✅ All validations passed"

test: ## Run all tests
	@echo "🧪 Running tests..."
	@./scripts/security-audit.sh
	@./scripts/compliance-check.sh
	@echo "✅ All tests passed"

deploy-dev: ## Deploy development environment
	@echo "🚀 Deploying development environment..."
	@./scripts/fully-automated-deploy.sh dev

deploy-prod: ## Deploy production environment
	@echo "🚀 Deploying production environment..."
	@./scripts/fully-automated-deploy.sh prod

destroy: ## Destroy infrastructure
	@echo "🧹 Cleaning up resources..."
	@./scripts/cleanup.sh $(ENV)

security-scan: ## Run security scans
	@echo "🔒 Running security scans..."
	@./scripts/security-scan.sh

performance-test: ## Run performance tests
	@echo "⚡ Running performance tests..."
	@./scripts/performance-report.sh
	@./scripts/benchmark.sh

setup-dev: ## Setup development environment
	@echo "🛠️ Setting up development environment..."
	@./scripts/setup-dev-environment.sh

benchmark: ## Run Kubernetes benchmarks
	@echo "⚡ Running benchmarks..."
	@./scripts/benchmark.sh

clean: ## Clean temporary files
	@echo "🧹 Cleaning temporary files..."
	@find . -name "*.log" -delete
	@find . -name ".terraform" -type d -exec rm -rf {} +
	@find . -name "terraform.tfstate*" -delete# Updated Sun Nov  9 12:52:18 CET 2025
