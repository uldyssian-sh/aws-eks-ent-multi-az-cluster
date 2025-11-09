#!/bin/bash

set -e

echo "🗑️ Starting automated cleanup"

# Setup environment
./scripts/setup-environment.sh

# Use auto-detected environment
ENVIRONMENT=${EKS_ENVIRONMENT:-dev}

# Destroy infrastructure
./scripts/destroy.sh $ENVIRONMENT

echo "✅ Full cleanup completed!"# Updated Sun Nov  9 12:50:06 CET 2025
