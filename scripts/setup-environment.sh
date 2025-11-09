#!/bin/bash

set -e

# Auto-detect environment based on git branch or default to dev
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    case $BRANCH in
        main|master) ENVIRONMENT="prod" ;;
        staging) ENVIRONMENT="staging" ;;
        *) ENVIRONMENT="dev" ;;
    esac
else
    ENVIRONMENT="dev"
fi

AWS_REGION="us-west-2"

echo "🔧 Auto-detected environment: $ENVIRONMENT"
echo "🌍 Region: $AWS_REGION"

# Export for other scripts
export EKS_ENVIRONMENT=$ENVIRONMENT
export EKS_AWS_REGION=$AWS_REGION

# Create terraform.tfvars if not exists
TFVARS_FILE="terraform/environments/$ENVIRONMENT/terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    echo "📝 Creating $TFVARS_FILE"
    if ! mkdir -p "$(dirname "$TFVARS_FILE")"; then
        echo "❌ Failed to create directory"
        exit 1
    fi
    cat > "$TFVARS_FILE" << EOF
aws_region = "$AWS_REGION"
EOF
fi

echo "✅ Environment setup complete"# Updated Sun Nov  9 12:50:06 CET 2025
