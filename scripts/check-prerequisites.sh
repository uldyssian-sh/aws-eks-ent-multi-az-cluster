#!/bin/bash

# Enterprise EKS Prerequisites Checker
# Validates all required tools and configurations for enterprise deployment

set -euo pipefail

REQUIRED_TOOLS=("aws" "kubectl" "terraform" "helm" "jq")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/prerequisites.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# Check if required tools are installed
check_tools() {
    log "Checking required tools..."
    local missing_tools=()
    
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "${tool}" &> /dev/null; then
            missing_tools+=("${tool}")
        else
            log "✓ ${tool} is installed"
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log "❌ Missing tools: ${missing_tools[*]}"
        exit 1
    fi
}

# Check AWS credentials with proper error handling
check_aws_credentials() {
    log "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log "❌ AWS credentials not configured"
        exit 1
    fi
    
    # Safe JSON parsing with error handling
    if command -v jq &> /dev/null; then
        local account_id
        local user_arn
        account_id=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "unknown")
        user_arn=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "unknown")
        log "✓ AWS Account: ${account_id}"
        log "✓ User ARN: ${user_arn}"
    else
        log "✓ AWS credentials configured (jq not available for detailed info)"
    fi
}

# Check kubectl configuration
check_kubectl() {
    log "Checking kubectl configuration..."
    
    if ! kubectl cluster-info &> /dev/null; then
        log "⚠️  kubectl not configured for any cluster"
    else
        local context
        context=$(kubectl config current-context 2>/dev/null || echo "unknown")
        log "✓ kubectl configured for context: ${context}"
    fi
}

# Check disk space with proper arithmetic handling
check_disk_space() {
    log "Checking disk space..."
    
    local available_gb
    local space_num
    
    # Get available space in GB, handle decimal values properly
    space_num=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    # Convert to integer for arithmetic operations
    available_gb=${space_num%.*}
    
    if [ "${available_gb}" -lt 10 ]; then
        log "❌ Insufficient disk space: ${available_gb}GB available, 10GB required"
        exit 1
    else
        log "✓ Sufficient disk space: ${available_gb}GB available"
    fi
}

# Check Terraform version
check_terraform_version() {
    log "Checking Terraform version..."
    
    local tf_version
    tf_version=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1 | cut -d' ' -f2 | sed 's/v//')
    
    log "✓ Terraform version: ${tf_version}"
}

# Main execution
main() {
    log "Starting enterprise prerequisites check..."
    
    check_tools
    check_aws_credentials
    check_kubectl
    check_disk_space
    check_terraform_version
    
    log "✅ All prerequisites check passed"
}

main "$@"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
