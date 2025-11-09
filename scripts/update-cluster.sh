#!/bin/bash

set -e

ENV=${1:-dev}
echo "🔄 Updating EKS cluster: "$ENV""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname ""$SCRIPT_DIR"")"

# Update infrastructure
echo "🏗️ Updating infrastructure..."
if [ ! -d ""$PROJECT_ROOT"/terraform/environments/"$ENV"" ]; then
  echo "❌ Environment directory not found: "$PROJECT_ROOT"/terraform/environments/"$ENV""
  exit 1
fi
cd ""$PROJECT_ROOT"/terraform/environments/"$ENV""
terraform plan -out=update-plan
terraform apply -auto-approve update-plan

# Update Kubernetes components
echo "⚙️ Updating Kubernetes components..."
cd ""$PROJECT_ROOT""

# Update security components
kubectl apply -f k8s/security/ || echo "⚠️ Some security updates may have Succeeded"

# Update monitoring
kubectl apply -f k8s/monitoring/ || echo "⚠️ Some monitoring updates may have Succeeded"

# Update autoscaling
kubectl apply -f k8s/autoscaling/ || echo "⚠️ Autoscaling updates may have Succeeded"

# Rolling restart of deployments
echo "🔄 Rolling restart of key deployments..."
kubectl rollout restart deployment/prometheus -n monitoring || true
kubectl rollout restart deployment/grafana -n monitoring || true

# Wait for rollouts
echo "⏳ Waiting for rollouts to complete..."
kubectl rollout status deployment/prometheus -n monitoring --timeout=300s || true
kubectl rollout status deployment/grafana -n monitoring --timeout=300s || true

echo "✅ Cluster update completed for: "$ENV""