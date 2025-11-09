# Contributing to AWS EKS Enterprise Multi-AZ Cluster

Thank you for your interest in contributing! This document provides guidelines for contributing to this enterprise-grade Kubernetes platform.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code.

## How to Contribute

### 1. Fork and Clone
```bash
git clone https://github.com/YOUR_USERNAME/aws-eks-ent-multi-az-cluster.git
cd aws-eks-ent-multi-az-cluster
```

### 2. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 3. Development Standards

#### Security Requirements
- No hardcoded secrets or credentials
- All infrastructure as code
- Security scanning required
- Encrypted data at rest and in transit

#### Code Quality
- Terraform code must pass `terraform validate`
- Shell scripts must pass `shellcheck`
- Kubernetes manifests must pass `kubeval`
- All changes must include tests

#### Documentation
- Update README.md for user-facing changes
- Add inline comments for complex logic
- Include deployment instructions

### 4. Testing
```bash
# Run security scan
./scripts/security-scan.sh

# Run compliance check
./scripts/compliance-check.sh

# Validate Terraform
terraform validate

# Test deployment
./scripts/fully-automated-deploy.sh dev
```

### 5. Submit Pull Request

#### PR Requirements
- Clear description of changes
- Link to related issues
- Security review completed
- Tests passing

#### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Security Checklist
- [ ] No hardcoded secrets
- [ ] Security scan passed
- [ ] Compliance check passed

## Testing
- [ ] Tests added/updated
- [ ] Manual testing completed
- [ ] Deployment tested
```

## Development Environment

### Prerequisites
- AWS CLI configured
- kubectl installed
- Terraform >= 1.0
- Docker installed
- GitHub CLI (optional)

### Local Setup
```bash
# Install dependencies
./scripts/check-prerequisites.sh

# Setup development environment
./scripts/setup-dev-environment.sh
```

## Architecture Guidelines

### Infrastructure as Code
- All infrastructure defined in Terraform
- Modular design with reusable components
- Environment-specific configurations
- State management with remote backend

### Security First
- Zero-trust networking
- Least privilege access
- Encrypted everything
- Continuous monitoring

### High Availability
- Multi-AZ deployment
- No single points of failure
- Automated failover
- Disaster recovery tested

## Release Process

1. **Feature Development**: Feature branches from `main`
2. **Testing**: Automated testing in CI/CD
3. **Security Review**: Security team approval
4. **Staging Deployment**: Test in staging environment
5. **Production Release**: Tagged release with changelog

## Questions?

- Create an issue for bugs or feature requests
- Join our Slack channel for discussions
- Email maintainers for security concerns

Thank you for contributing to enterprise-grade infrastructure!