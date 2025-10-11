#!/bin/bash

set -e

REGION=${AWS_REGION:-us-west-2}
CLUSTER_NAME=${CLUSTER_NAME:-aws-eks-ent-multi-az-cluster-prod}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploying production enterprise stack"
echo "🌍 Region: $REGION"
echo "🏢 Cluster: $CLUSTER_NAME"

# Deploy infrastructure
cd "$PROJECT_ROOT/terraform/environments/prod"
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Configure kubectl
aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"

# Wait for nodes
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# Deploy production components
cd "$PROJECT_ROOT"

# Security stack
echo "📦 Deploying security stack..."
kubectl apply -f k8s/security/ || { echo "❌ Security deployment failed"; exit 1; }
kubectl apply -f k8s/policies/ || { echo "❌ Policies deployment failed"; exit 1; }

# Production monitoring (double resources)
echo "📊 Deploying production monitoring..."
kubectl apply -f k8s/monitoring/prometheus-prod.yaml || { echo "❌ Prometheus deployment failed"; exit 1; }
kubectl apply -f k8s/monitoring/grafana-prod.yaml || { echo "❌ Grafana deployment failed"; exit 1; }
kubectl apply -f k8s/monitoring/grafana-secret.yaml || { echo "❌ Grafana secret deployment failed"; exit 1; }

# GitOps
echo "🔄 Deploying GitOps..."
kubectl apply -f k8s/gitops/ || { echo "❌ GitOps deployment failed"; exit 1; }

# Service Mesh
echo "🌐 Deploying service mesh..."
kubectl apply -f k8s/service-mesh/ || { echo "❌ Service mesh deployment failed"; exit 1; }

echo "✅ Production enterprise stack deployed"
echo "📊 Resources: 2x dev environment"
echo "🔗 Access: kubectl port-forward -n monitoring svc/grafana 3000:3000"