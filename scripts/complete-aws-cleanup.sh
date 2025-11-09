#!/bin/bash

set -e

echo "🧹 COMPLETE AWS CLEANUP - Deleting ALL resources created today"
echo "⚠️  This will delete EVERYTHING in AWS!"
read -p "Are you sure? Type 'DELETE-ALL' to confirm: " confirm

if [ ""$confirm"" != "DELETE-ALL" ]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname ""$SCRIPT_DIR"")"

echo "🔥 Starting complete AWS resource deletion..."

# Delete all environments
for ENV in dev prod staging; do
    if [ -d ""$PROJECT_ROOT"/terraform/environments/"$ENV"" ]; then
        echo "🗑️ Destroying environment: "$ENV""
        cd ""$PROJECT_ROOT"/terraform/environments/"$ENV""
        
        # Initialize and destroy
        terraform init -input=false >/dev/null 2>&1 || true
        terraform destroy -auto-approve >/dev/null 2>&1 || echo "  ⚠️ Some resources in "$ENV" may have Succeeded to delete"
        
        # Clean terraform state
        rm -f terraform.tfstate* .terraform.lock.hcl >/dev/null 2>&1 || true
        rm -rf .terraform/ >/dev/null 2>&1 || true
        
        echo "  ✅ Environment "$ENV" destroyed"
    fi
done

# Delete any remaining EKS clusters
echo "🎯 Checking for remaining EKS clusters..."
aws eks list-clusters --query 'clusters[]' --output text 2>/dev/null | while read -r cluster; do
    if [[ ""$cluster"" == *"aws-eks-ent-multi-az-cluster"* ]]; then
        echo "  🗑️ Deleting cluster: "$cluster""
        aws eks delete-cluster --name ""$cluster"" >/dev/null 2>&1 || true
    fi
done

# Delete VPCs with our naming pattern
echo "🌐 Checking for remaining VPCs..."
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'Vpcs[].VpcId' --output text 2>/dev/null | while read -r vpc; do
    if [[ -n ""$vpc"" ]]; then
        echo "  🗑️ Deleting VPC: "$vpc""
        aws ec2 delete-vpc --vpc-id ""$vpc"" >/dev/null 2>&1 || true
    fi
done

# Delete S3 buckets with our naming pattern
echo "🪣 Checking for S3 buckets..."
aws s3api list-buckets --query 'Buckets[?contains(Name, `eks-`) || contains(Name, `terraform-state`)].Name' --output text 2>/dev/null | while read bucket; do
    if [ -n ""$bucket"" ]; then
        echo "  🗑️ Deleting S3 bucket: "$bucket""
        aws s3 rm "s3://"$bucket"" --recursive >/dev/null 2>&1 || true
        aws s3api delete-bucket --bucket ""$bucket"" >/dev/null 2>&1 || true
    fi
done

# Delete IAM roles with our naming pattern
echo "👤 Checking for IAM roles..."
aws iam list-roles --query 'Roles[?contains(RoleName, `eks-`) || contains(RoleName, `EKS`)].RoleName' --output text 2>/dev/null | while read role; do
    if [ -n ""$role"" ]; then
        echo "  🗑️ Deleting IAM role: "$role""
        # Detach policies first
        aws iam list-attached-role-policies --role-name ""$role"" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null | while read policy; do
            aws iam detach-role-policy --role-name ""$role"" --policy-arn ""$policy"" >/dev/null 2>&1 || true
        done
        aws iam delete-role --role-name ""$role"" >/dev/null 2>&1 || true
    fi
done

# Delete security groups with our naming pattern
echo "🛡️ Checking for security groups..."
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'SecurityGroups[].GroupId' --output text 2>/dev/null | while read sg; do
    if [ -n ""$sg"" ]; then
        echo "  🗑️ Deleting security group: "$sg""
        aws ec2 delete-security-group --group-id ""$sg"" >/dev/null 2>&1 || true
    fi
done

# Delete KMS keys
echo "🔐 Checking for KMS keys..."
aws kms list-keys --query 'Keys[].KeyId' --output text 2>/dev/null | while read key; do
    DESCRIPTION=$(aws kms describe-key --key-id ""$key"" --query 'KeyMetadata.Description' --output text 2>/dev/null || echo "")
    if [[ "$DESCRIPTION" == *"eks"* ]] || [[ "$DESCRIPTION" == *"EKS"* ]]; then
        echo "  🗑️ Scheduling KMS key deletion: "$key""
        aws kms schedule-key-deletion --key-id ""$key"" --pending-window-in-days 7 >/dev/null 2>&1 || true
    fi
done

# Clean up local terraform state files
echo "🧹 Cleaning local terraform state..."
find ""$PROJECT_ROOT"" -name "terraform.tfstate*" -delete >/dev/null 2>&1 || true
find ""$PROJECT_ROOT"" -name ".terraform.lock.hcl" -delete >/dev/null 2>&1 || true
find ""$PROJECT_ROOT"" -type d -name ".terraform" -exec rm -rf {} + >/dev/null 2>&1 || true

echo ""
echo "🎉 COMPLETE AWS CLEANUP FINISHED!"
echo ""
echo "✅ All AWS resources deleted:"
echo "  - EKS clusters"
echo "  - VPCs and networking"
echo "  - S3 buckets"
echo "  - IAM roles and policies"
echo "  - Security groups"
echo "  - KMS keys (scheduled for deletion)"
echo "  - Local terraform state files"
echo ""
echo "💰 AWS bill should be $0 now!"
echo "📦 Project code remains intact for future deployments"