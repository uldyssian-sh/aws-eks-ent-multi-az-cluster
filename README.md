# AWS AWS AWS EKS Enterprise Multi-AZ Cluster

<div align="center">

```
┌─────────────────────────────────────────────────────────────┐
│            AWS AWS AWS EKS Enterprise Multi-AZ                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   AZ-2a     │    │   AZ-2b     │    │   AZ-2c     │     │
│  │ ┌─────────┐ │    │ ┌─────────┐ │    │ ┌─────────┐ │     │
│  │ │ Nodes   │ │    │ │ Nodes   │ │    │ │ Nodes   │ │     │
│  │ └─────────┘ │    │ └─────────┘ │    │ └─────────┘ │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                   │                   │          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              EKS Control Plane                     │   │
│  │            (Multi-AZ Managed)                      │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4.svg)](https://www.terraform.io/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900.svg)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5.svg)](https://kubernetes.io/)
[![Multi-AZ](https://img.shields.io/badge/Multi--AZ-High%20Availability-green.svg)](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)

</div>

## 🏢 Enterprise-Grade Kubernetes Platform

Highly available, production-ready EKS cluster spanning multiple Availability Zones. Designed for mission-critical workloads with advanced security, monitoring, disaster recovery, and compliance capabilities.

## ⚡ Key Features

### High Availability & Resilience
- **Multi-AZ Deployment** - Nodes distributed across 3 availability zones
- **Auto Scaling** - Cluster and pod autoscaling with predictive scaling
- **Load Balancing** - Application Load Balancer with health checks
- **Disaster Recovery** - Cross-region backup and automated failover

### Enterprise Security
- **Private Subnets** - Worker nodes isolated in private subnets
- **IAM Integration** - Fine-grained access control with RBAC
- **Network Policies** - Pod-to-pod communication control
- **Secrets Management** - AWS Secrets Manager and KMS integration
- **Image Scanning** - Container vulnerability scanning with Trivy

### Observability & Monitoring
- **CloudWatch Container Insights** - Native AWS monitoring
- **Prometheus & Grafana** - Custom metrics and dashboards
- **Jaeger Tracing** - Distributed request tracing
- **Centralized Logging** - Fluentd with CloudWatch Logs

## 🚀 Quick Deployment

### Prerequisites
```bash
# Required tools
aws-cli >= 2.0
terraform >= 1.5
kubectl >= 1.28
helm >= 3.0
```

### Infrastructure Deployment
```bash
# Clone repository
git clone https://github.com/uldyssian-sh/aws-eks-ent-multi-az-cluster.git
cd aws-eks-ent-multi-az-cluster

# Configure variables
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
# Edit terraform.tfvars with your settings

# Deploy infrastructure
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name aws-eks-ent-multi-az-cluster-dev

# Verify deployment
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🏗️ Architecture Components

### Node Groups
- **System Nodes** - Dedicated for system components (3-9 nodes)
- **Application Nodes** - General workloads (6-30 nodes)
- **Database Nodes** - Stateful workloads with taints (3-12 nodes)

### Networking
- **VPC Configuration** - Custom VPC with public/private subnets
- **CNI Plugin** - AWS VPC CNI with security groups for pods
- **Ingress Controller** - AWS Load Balancer Controller
- **Service Mesh** - Istio for advanced traffic management

### Storage
- **EBS CSI Driver** - Dynamic persistent volume provisioning
- **EFS CSI Driver** - Shared file system storage
- **Storage Classes** - Multiple performance tiers (gp3, io2, st1)

## 📊 Monitoring Stack

### Metrics Collection
```yaml
# Prometheus configuration
prometheus:
  retention: 30d
  storage: 100Gi
  replicas: 2
  
grafana:
  persistence: true
  dashboards:
    - kubernetes-cluster
    - kubernetes-pods
    - aws-load-balancer
```

### Alerting Rules
- **Cluster Health** - Node and pod availability
- **Resource Utilization** - CPU, memory, storage thresholds
- **Application Performance** - Response time and error rates
- **Security Events** - Failed authentication attempts

## 🔒 Security Hardening

### Network Security
```yaml
# Network policies example
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### Pod Security Standards
- **Restricted** - Production workloads
- **Baseline** - Development environments
- **Privileged** - System components only

## 📚 Documentation

### Getting Started
- **[Enterprise Deployment Guide](docs/ENTERPRISE_DEPLOYMENT.md)** - Complete deployment instructions
- **[Prerequisites Check](scripts/check-prerequisites.sh)** - Validate environment setup
- **[Configuration Examples](terraform/environments/dev/terraform.tfvars.example)** - Sample configurations

### Operations
- **[Security Scanning](scripts/security-scan.sh)** - Automated security assessment
- **[Monitoring Setup](k8s/monitoring/)** - Prometheus and Grafana configuration
- **[Backup Validation](scripts/verify-backups.sh)** - Backup verification procedures

### Kubernetes Manifests
- **[Monitoring Stack](k8s/monitoring/)** - Complete monitoring deployment
- **[Security Policies](k8s/security/)** - Network policies and security configurations
- **[Ingress Configuration](k8s/ingress/)** - Load balancer and ingress setup

## 🔗 Integration

### CI/CD Pipeline
- **[GitHub Actions](.github/workflows/enterprise-ci.yml)** - Automated testing and deployment
- **[Security Scanning](.github/workflows/security.yml)** - Vulnerability assessment
- **[Cost Estimation](terraform/modules/cost-optimization/)** - Infrastructure cost analysis

### Terraform Modules
- **[EKS Module](terraform/modules/eks/)** - Complete EKS cluster configuration
- **[VPC Module](terraform/modules/vpc/)** - Network infrastructure
- **[Monitoring Module](terraform/modules/monitoring/)** - Observability stack

## 💰 Cost Optimization

### Strategies
- **Spot Instances** - 70% cost savings for fault-tolerant workloads
- **Reserved Instances** - Predictable workload cost reduction
- **Cluster Autoscaler** - Dynamic scaling based on demand
- **Fargate** - Serverless containers for variable workloads
- **Right-sizing** - Automated resource optimization

## 🤝 Contributing

1. **[Fork Repository](https://github.com/uldyssian-sh/aws-eks-ent-multi-az-cluster/fork)** - Create your fork
2. **[Development Setup](docs/ENTERPRISE_DEPLOYMENT.md)** - Local development environment
3. **[Submit Pull Request](https://github.com/uldyssian-sh/aws-eks-ent-multi-az-cluster/pulls)** - Contribute improvements

## 📄 License

This project is licensed under the MIT License - see the **[LICENSE](LICENSE)** file for details.

## 🆘 Support

- **[GitHub Issues](https://github.com/uldyssian-sh/aws-eks-ent-multi-az-cluster/issues)** - Bug reports and feature requests
- **[Community Support](https://github.com/uldyssian-sh/aws-eks-ent-multi-az-cluster/issues)** - Community support and Q&A
- **[Security Policy](SECURITY.md)** - Vulnerability reporting
- **[AWS EKS Documentation](https://docs.aws.amazon.com/eks/)** - Official AWS EKS documentation# Trigger deployment
# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
