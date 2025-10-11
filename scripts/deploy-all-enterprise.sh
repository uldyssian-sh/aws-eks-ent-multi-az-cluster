#!/bin/bash

set -e

ENV=${1:-dev}
REGION=${2:-us-west-2}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploying complete enterprise stack: $ENV"

# Deploy infrastructure
cd "$PROJECT_ROOT/terraform/environments/$ENV"
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Configure kubectl
aws eks --region "$REGION" update-kubeconfig --name "aws-eks-ent-multi-az-cluster-$ENV"

# Wait for nodes
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# Deploy all components
cd "$PROJECT_ROOT"

# Security stack
echo "📦 Deploying security stack..."
kubectl apply -f k8s/security/ || { echo "❌ Security deployment failed"; exit 1; }
kubectl apply -f k8s/policies/ || { echo "❌ Policies deployment failed"; exit 1; }

# Monitoring
echo "📊 Deploying monitoring..."
kubectl apply -f k8s/monitoring/ || { echo "❌ Monitoring deployment failed"; exit 1; }

# GitOps
echo "🔄 Deploying GitOps..."
kubectl apply -f k8s/gitops/ || { echo "❌ GitOps deployment failed"; exit 1; }

# Service Mesh
echo "🌐 Deploying service mesh..."
kubectl apply -f k8s/service-mesh/ || { echo "❌ Service mesh deployment failed"; exit 1; }

# Chaos Engineering
echo "🐒 Deploying chaos engineering..."
kubectl apply -f k8s/chaos/ || { echo "❌ Chaos engineering deployment failed"; exit 1; }

echo "✅ Complete enterprise stack deployed: $ENV"
echo "🔗 Access points:"
echo "  Grafana: kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo "  ArgoCD: kubectl port-forward -n argocd svc/argocd-server 8080:80"