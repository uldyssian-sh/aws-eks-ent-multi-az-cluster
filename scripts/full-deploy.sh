#!/bin/bash

set -e

echo "🚀 Starting automated EKS deployment"

# Setup environment
./scripts/setup-environment.sh

# Use auto-detected environment
ENVIRONMENT=${EKS_ENVIRONMENT:-dev}
AWS_REGION=${EKS_AWS_REGION:-us-west-2}

# Deploy infrastructure
./scripts/deploy.sh $ENVIRONMENT $AWS_REGION

# Validate deployment
./scripts/validate-cluster.sh

echo "🎉 Full deployment completed successfully!"# Updated Sun Nov  9 12:50:06 CET 2025
