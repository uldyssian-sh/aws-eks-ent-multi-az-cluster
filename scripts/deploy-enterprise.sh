#!/bin/bash

set -e

# Check required tools
for tool in terraform aws kubectl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "❌ Required tool not found: $tool"
    exit 1
  fi
done

ENV=${1:-dev}
REGION=${2:-us-west-2}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploying enterprise EKS: $ENV"

# Deploy infrastructure
if [ ! -d "$PROJECT_ROOT/terraform/environments/$ENV" ]; then
  echo "❌ Environment directory not found: $PROJECT_ROOT/terraform/environments/$ENV"
  exit 1
fi
cd "$PROJECT_ROOT/terraform/environments/$ENV"
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Configure kubectl
aws eks --region "$REGION" update-kubeconfig --name "aws-eks-ent-multi-az-cluster-$ENV"

# Wait for nodes
kubectl wait --for=condition=Ready nodes --all --timeout=300s

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

echo "✅ Enterprise EKS deployed: $ENV"