#!/bin/bash

set -e

ENV=${1:-dev}
REGION=${2:-us-west-2}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🤖 FULLY AUTOMATED DEPLOYMENT - NO HUMAN INTERACTION"
echo "🚀 Environment: $ENV"
echo "🌍 Region: $REGION"
echo "⏰ Started: $(date)"

# Pre-flight checks
echo "🔍 Pre-flight checks..."
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not installed"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not installed"; exit 1; }

# Check AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured"; exit 1; }

echo "✅ All prerequisites met"

# Deploy infrastructure
echo "🏗️ Deploying infrastructure..."
cd "$PROJECT_ROOT/terraform/environments/$ENV"
terraform init -input=false
terraform plan -out=tfplan -input=false
terraform apply -auto-approve tfplan

# Configure kubectl
echo "⚙️ Configuring kubectl..."
aws eks --region "$REGION" update-kubeconfig --name "aws-eks-ent-multi-az-cluster-$ENV"

# Wait for cluster readiness
echo "⏳ Waiting for cluster readiness..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# Deploy all components automatically
cd "$PROJECT_ROOT"

echo "🔐 Deploying security stack..."
kubectl apply -f k8s/security/ --wait=true
kubectl apply -f k8s/policies/ --wait=true

echo "📊 Deploying monitoring..."
if [ "$ENV" = "prod" ]; then
    kubectl apply -f k8s/monitoring/prometheus-prod.yaml --wait=true
    kubectl apply -f k8s/monitoring/grafana-prod.yaml --wait=true
else
    kubectl apply -f k8s/monitoring/ --wait=true
fi

echo "🔄 Deploying GitOps..."
kubectl apply -f k8s/gitops/ --wait=true

echo "🌐 Deploying service mesh..."
kubectl apply -f k8s/service-mesh/ --wait=true

echo "🐒 Deploying chaos engineering..."
kubectl apply -f k8s/chaos/ --wait=true

# Wait for all deployments
echo "⏳ Waiting for all deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -A

echo "🎉 FULLY AUTOMATED DEPLOYMENT COMPLETE!"
echo "⏰ Completed: $(date)"
echo "🔗 Access points:"
echo "  Grafana: kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo "  ArgoCD: kubectl port-forward -n argocd svc/argocd-server 8080:80"
echo ""
echo "📊 Cluster status:"
kubectl get nodes
kubectl get pods -A --field-selector=status.phase!=Running | grep -v "Completed" || echo "✅ All pods running"# Updated Sun Nov  9 12:50:06 CET 2025
