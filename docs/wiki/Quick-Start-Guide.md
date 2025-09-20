# Quick Start Guide

Get your enterprise EKS cluster running in **15 minutes** with zero-touch automation.

## 📋 Prerequisites

Before starting, ensure you have the required tools and permissions:

### 🛠️ Required Tools
- **[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)** v2.0+ configured with appropriate permissions
- **[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)** v1.28+ for Kubernetes management
- **[Terraform](https://developer.hashicorp.com/terraform/downloads)** v1.5+ for infrastructure provisioning
- **[Docker](https://docs.docker.com/get-docker/)** for container operations
- **[Git](https://git-scm.com/downloads)** for repository management
- **Bash shell** (Linux/macOS/WSL)

### 🔑 AWS Permissions
Your AWS credentials need the following permissions:
- **EKS**: Full access to create and manage clusters
- **EC2**: VPC, subnets, security groups, instances
- **IAM**: Create roles and policies for EKS
- **CloudWatch**: Logging and monitoring
- **S3**: Terraform state storage (optional)

**Quick permission check:**
```bash
aws sts get-caller-identity
aws eks list-clusters --region us-west-2
```

## 🚀 One-Command Deployment

### Step 1: Clone Repository
```bash
git clone https://github.com/uldyssian-sh/aws-eks-ent-multi-az-cluster.git
cd aws-eks-ent-multi-az-cluster
```

### Step 2: Prerequisites Check
```bash
# Verify all requirements
./scripts/check-prerequisites.sh

# Or use Makefile
make validate
```

### Step 3: Deploy Environment

#### Development Environment (15 minutes)
```bash
# Using automation script
./scripts/fully-automated-deploy.sh dev

# Or using Makefile
make deploy-dev
```

#### Production Environment (20 minutes)
```bash
# Using automation script
./scripts/fully-automated-deploy.sh prod

# Or using Makefile
make deploy-prod
```

## 📊 Verify Deployment

### Check Cluster Status
```bash
# Verify cluster is running
kubectl get nodes

# Check all system pods
kubectl get pods -A

# Verify cluster info
kubectl cluster-info
```

### Access Monitoring Dashboards

#### Grafana Dashboard
```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Open in browser: http://localhost:3000
# Default credentials: admin/admin (change on first login)
```

#### Prometheus Metrics
```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Open in browser: http://localhost:9090
```

#### ArgoCD GitOps
```bash
# Port forward to ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:80

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Open in browser: http://localhost:8080
```

## 🔧 Configuration Options

### Environment Variables
```bash
# Set your preferred region
export AWS_REGION=us-west-2

# Set cluster name
export CLUSTER_NAME=my-eks-cluster

# Set environment
export ENVIRONMENT=dev
```

### Terraform Variables
Edit `terraform/environments/dev/terraform.tfvars`:
```hcl
# Basic configuration
cluster_name = "my-eks-cluster"
region      = "us-west-2"
environment = "dev"

# Node configuration
node_instance_types = ["m5.large", "m5.xlarge"]
min_size            = 1
max_size            = 10
desired_size        = 3

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

# Features
enable_monitoring = true
enable_logging    = true
enable_backup     = true
```

## 🧹 Cleanup Resources

When you're done testing:

```bash
# Clean up development environment
./scripts/cleanup.sh dev

# Or using Makefile
make destroy ENV=dev

# Complete AWS cleanup (use with caution)
./scripts/complete-aws-cleanup.sh
```

## 🔍 Troubleshooting

### Common Issues

#### 1. AWS Credentials Not Configured
```bash
# Configure AWS CLI
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=us-west-2
```

#### 2. Insufficient Permissions
```bash
# Check current permissions
aws sts get-caller-identity

# Test EKS permissions
aws eks describe-cluster --name test-cluster --region us-west-2
```

#### 3. Terraform State Issues
```bash
# Initialize Terraform
cd terraform/environments/dev
terraform init

# Check state
terraform show
```

#### 4. kubectl Not Working
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name your-cluster-name

# Verify connection
kubectl get nodes
```

### Getting Help

- **[Troubleshooting Guide](Troubleshooting)** - Detailed troubleshooting
- **[GitHub Issues](https://github.com/uldyssian-sh/aws-eks-ent-multi-az-cluster/issues)** - Report bugs
- **[AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)** - Official AWS guide
- **[Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/troubleshooting/)** - K8s debugging

## 📚 Next Steps

After successful deployment:

1. **[System Architecture](System-Architecture)** - Understand your infrastructure
2. **[Security Standards](Security-Standards)** - Configure security policies
3. **[Monitoring Setup](Monitoring-Observability)** - Set up comprehensive monitoring
4. **[GitOps Workflows](GitOps-Workflows)** - Implement continuous deployment
5. **[Cost Optimization](Cost-Optimization)** - Optimize your spending

## 🎯 Quick Commands Reference

```bash
# Development workflow
make setup-dev          # Setup development environment
make validate           # Validate all configurations
make deploy-dev         # Deploy development cluster
make test              # Run security and compliance tests
make benchmark         # Run performance benchmarks

# Production workflow
make deploy-prod       # Deploy production cluster
make security-scan     # Run security scans
make performance-test  # Run performance tests

# Maintenance
make clean            # Clean temporary files
make destroy ENV=dev  # Destroy environment
```

## 🔗 Useful Links

- **[AWS EKS Getting Started](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)** - Official AWS guide
- **[Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)** - Learn Kubernetes
- **[Terraform AWS Tutorial](https://learn.hashicorp.com/tutorials/terraform/aws-build)** - Infrastructure as Code
- **[GitOps Guide](https://www.gitops.tech/)** - GitOps principles and practices

---

**Ready to deploy? Run `make deploy-dev` and get started in 15 minutes! 🚀**