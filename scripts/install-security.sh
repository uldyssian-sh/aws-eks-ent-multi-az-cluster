#!/bin/bash

set -e

echo "🔒 Installing security stack"

# Install Falco
kubectl apply -f k8s/security/falco.yaml >/dev/null

# Install External Secrets
kubectl apply -f k8s/security/external-secrets.yaml >/dev/null

# Install Gatekeeper
kubectl apply -f k8s/security/gatekeeper.yaml >/dev/null

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/external-secrets -n external-secrets >/dev/null 2>&1 || true
kubectl wait --for=condition=available --timeout=300s deployment/gatekeeper-controller-manager -n gatekeeper-system >/dev/null 2>&1 || true

# Apply policies
kubectl apply -f k8s/policies/ >/dev/null 2>&1 || true

echo "✅ Security stack installed"# Updated Sun Nov  9 12:50:06 CET 2025
