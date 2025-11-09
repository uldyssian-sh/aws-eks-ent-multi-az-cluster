# EKS Multi-AZ Cluster Deployment

## Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- kubectl
- Helm

## Quick Start
```bash
# Deploy dev environment
cd terraform/environments/dev
terraform init
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name aws-eks-ent-multi-az-cluster-dev
```

## Environments
- **dev**: Development environment (3 nodes, t3.medium)
- **prod**: Production environment (6 nodes, m5.large, HA)

## Features
- Multi-AZ deployment across 3 availability zones
- KMS encryption for secrets
- CloudWatch monitoring and alerting
- AWS Backup integration
- Security groups and NACLs
- IRSA (IAM Roles for Service Accounts)

## Cleanup
```bash
./scripts/cleanup.sh dev
```# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
