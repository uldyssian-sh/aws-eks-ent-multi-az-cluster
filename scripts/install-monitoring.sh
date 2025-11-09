#!/bin/bash

set -e

echo "📊 Installing monitoring stack"

# Install Prometheus and Grafana
kubectl apply -f k8s/monitoring/ || { echo "❌ Monitoring deployment failed"; exit 1; }

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring || { echo "❌ Prometheus not ready"; exit 1; }
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring || { echo "❌ Grafana not ready"; exit 1; }

# Enable Container Insights
aws logs create-log-group --log-group-name /aws/containerinsights/$1/application >/dev/null 2>&1 || true
aws logs create-log-group --log-group-name /aws/containerinsights/$1/host >/dev/null 2>&1 || true
aws logs create-log-group --log-group-name /aws/containerinsights/$1/dataplane >/dev/null 2>&1 || true

echo "✅ Monitoring stack installed"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
