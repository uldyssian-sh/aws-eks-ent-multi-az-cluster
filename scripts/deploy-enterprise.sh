#!/bin/bash
# Enterprise EKS deployment script
# Deploys complete EKS infrastructure with security and monitoring

set -euo pipefail

# Check required tools
for tool in terraform aws kubectl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "❌ Required tool not found: $tool"
    echo "Please install $tool and try again"
    exit 1
  fi
done

ENV=${1:-dev}
REGION=${2:-us-west-2}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploying enterprise EKS: $ENV"

# Deploy infrastructure
if [[ ! -d "$PROJECT_ROOT/terraform/environments/$ENV" ]]; then
  echo "❌ Environment directory not found: $PROJECT_ROOT/terraform/environments/$ENV"
  echo "Available environments:"
  ls -1 "$PROJECT_ROOT/terraform/environments/" 2>/dev/null || echo "No environments found"
  exit 1
fi

cd "$PROJECT_ROOT/terraform/environments/$ENV"
echo "📋 Initializing Terraform..."
terraform init || { echo "❌ Terraform init failed"; exit 1; }

echo "📋 Planning Terraform deployment..."
terraform plan -out=tfplan || { echo "❌ Terraform plan failed"; exit 1; }

echo "🚀 Applying Terraform configuration..."
terraform apply -auto-approve tfplan || { echo "❌ Terraform apply failed"; exit 1; }

# Configure kubectl
echo "⚙️ Configuring kubectl..."
aws eks --region "$REGION" update-kubeconfig --name "aws-eks-ent-multi-az-cluster-$ENV" || {
  echo "❌ Failed to configure kubectl"
  exit 1
}

# Verify cluster connectivity
echo "🔍 Verifying cluster connectivity..."
kubectl cluster-info || { echo "❌ Cannot connect to cluster"; exit 1; }

# Wait for nodes
echo "⏳ Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || {
  echo "❌ Nodes failed to become ready"
  kubectl get nodes
  exit 1
}

# Deploy security stack
cd "$PROJECT_ROOT"
echo "📦 Installing security stack..."
./scripts/install-security.sh || { echo "❌ Security installation failed"; exit 1; }

# Deploy monitoring
echo "📊 Deploying monitoring..."
kubectl apply -f k8s/monitoring/ || { echo "❌ Monitoring deployment failed"; exit 1; }

# Apply policies
echo "📜 Applying policies..."
kubectl apply -f k8s/policies/ || echo "⚠️ Some policies may have failed (non-critical)"

echo "✅ Enterprise EKS deployed: $ENV"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
