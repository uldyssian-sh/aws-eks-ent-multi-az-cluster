#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-west-2}

aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS not configured"; exit 1; }
cd "terraform/environments/"$ENVIRONMENT""
terraform init -input=false >/dev/null 2>&1
terraform apply -input=false -auto-approve >/dev/null 2>&1
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null)
aws eks --region "$AWS_REGION" update-kubeconfig --name "$CLUSTER_NAME" >/dev/null 2>&1
kubectl wait --for=condition=Ready nodes --all --timeout=300s >/dev/null 2>&1
echo "✅ "$CLUSTER_NAME" ready"