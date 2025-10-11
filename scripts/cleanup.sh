#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-west-2}

echo "🗑️ Cleaning AWS: $ENVIRONMENT"

# Try terraform destroy first
cd "terraform/environments/$ENVIRONMENT"
terraform destroy -auto-approve -input=false >/dev/null 2>&1 || {
  cd ../../../
  
  # Force cleanup all resources
  # Delete node groups
  aws eks list-nodegroups --cluster-name "aws-eks-ent-multi-az-cluster-$ENVIRONMENT" --region "$AWS_REGION" --query 'nodegroups' --output text 2>/dev/null | xargs -n1 -I {} aws eks delete-nodegroup --cluster-name "aws-eks-ent-multi-az-cluster-$ENVIRONMENT" --nodegroup-name {} --region "$AWS_REGION" >/dev/null 2>&1 || true
  
  # Wait and delete cluster
  aws eks wait nodegroup-deleted --cluster-name "aws-eks-ent-multi-az-cluster-$ENVIRONMENT" --nodegroup-name "aws-eks-ent-multi-az-cluster-$ENVIRONMENT-nodes" --region "$AWS_REGION" >/dev/null 2>&1 || true
  aws eks delete-cluster --name "aws-eks-ent-multi-az-cluster-$ENVIRONMENT" --region "$AWS_REGION" >/dev/null 2>&1 || true
  aws eks wait cluster-deleted --name "aws-eks-ent-multi-az-cluster-$ENVIRONMENT" --region "$AWS_REGION" >/dev/null 2>&1 || true
  
  # Force delete all network resources with retries
  sleep 30  # Wait for resources to detach
  
  # Delete NAT gateways and wait
  aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'NatGateways[*].NatGatewayId' --output text | xargs -n1 aws ec2 delete-nat-gateway --region $AWS_REGION --nat-gateway-id >/dev/null 2>&1 || true
  sleep 60
  
  # Release EIPs
  aws ec2 describe-addresses --region $AWS_REGION --filters "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'Addresses[*].AllocationId' --output text | xargs -n1 aws ec2 release-address --region $AWS_REGION --allocation-id >/dev/null 2>&1 || true
  
  # Force delete security groups (retry multiple times)
  for j in {1..5}; do
    aws ec2 describe-security-groups --region $AWS_REGION --filters "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | xargs -n1 aws ec2 delete-security-group --region $AWS_REGION --group-id >/dev/null 2>&1 || true
    sleep 10
  done
  
  # Delete route table associations and route tables
  for vpc in $(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'Vpcs[*].VpcId' --output text); do
    # Delete route table associations
    aws ec2 describe-route-tables --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].Associations[*].RouteTableAssociationId' --output text | xargs -n1 aws ec2 disassociate-route-table --region $AWS_REGION --association-id >/dev/null 2>&1 || true
    
    # Delete custom route tables
    aws ec2 describe-route-tables --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | xargs -n1 aws ec2 delete-route-table --region $AWS_REGION --route-table-id >/dev/null 2>&1 || true
  done
  
  # Delete subnets
  aws ec2 describe-subnets --region $AWS_REGION --filters "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'Subnets[*].SubnetId' --output text | xargs -n1 aws ec2 delete-subnet --region $AWS_REGION --subnet-id >/dev/null 2>&1 || true
  
  # Delete internet gateways and VPCs
  for vpc in $(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'Vpcs[*].VpcId' --output text); do
    # Detach and delete internet gateways
    aws ec2 describe-internet-gateways --region $AWS_REGION --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[*].InternetGatewayId' --output text | xargs -n1 -I {} sh -c "aws ec2 detach-internet-gateway --region $AWS_REGION --internet-gateway-id {} --vpc-id $vpc >/dev/null 2>&1; aws ec2 delete-internet-gateway --region $AWS_REGION --internet-gateway-id {} >/dev/null 2>&1" || true
    
    # Force delete VPC (retry multiple times)
    for i in {1..10}; do
      aws ec2 delete-vpc --region "$AWS_REGION" --vpc-id "$vpc" >/dev/null 2>&1 && break || sleep 15
    done
  done
  
  # Delete IAM resources
  aws iam list-roles --query 'Roles[?contains(RoleName,`aws-eks-ent-multi-az-cluster-'$ENVIRONMENT'`)].RoleName' --output text | xargs -n1 -I {} sh -c 'aws iam list-attached-role-policies --role-name {} --query "AttachedPolicies[*].PolicyArn" --output text | xargs -n1 aws iam detach-role-policy --role-name {} --policy-arn; aws iam delete-role --role-name {}' >/dev/null 2>&1 || true
  aws iam list-policies --scope Local --query 'Policies[?contains(PolicyName,`aws-eks-ent-multi-az-cluster-'$ENVIRONMENT'`)].Arn' --output text | xargs -n1 aws iam delete-policy --policy-arn >/dev/null 2>&1 || true
  
  # Schedule KMS deletion
  aws kms list-keys --region $AWS_REGION --query 'Keys[*].KeyId' --output text | xargs -n1 -I {} sh -c 'aws kms describe-key --region $AWS_REGION --key-id {} --query "KeyMetadata.Description" --output text | grep -q "EKS Secret Encryption Key" && aws kms schedule-key-deletion --region $AWS_REGION --key-id {} --pending-window-in-days 7' >/dev/null 2>&1 || true
}

# Final verification
REMAINING_VPCS=$(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Project,Values=aws-eks-ent-multi-az-cluster" --query 'Vpcs[*].VpcId' --output text | wc -w)
if [ "$REMAINING_VPCS" -eq 0 ]; then
  echo "✅ Complete cleanup verified"
else
  echo "⚠️ $REMAINING_VPCS VPCs may need manual cleanup"
fi