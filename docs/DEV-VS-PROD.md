# Development vs Production Environments

## 🔧 Development Environment
**Resources:**
- EKS nodes: 3 (m5.large)
- Spot instances: 1-5
- Prometheus: 1 replica, 512Mi RAM, 500m CPU
- Grafana: 1 replica, 256Mi RAM, 250m CPU
- Log retention: 30 days

**Configuration:**
```bash
./scripts/deploy-all-enterprise.sh dev
```

## 🏭 Production Environment
**Resources (2x Dev):**
- EKS nodes: 6 (m5.large + m5a.large)
- Spot instances: 2-20
- Prometheus: 3 replicas, 4Gi RAM, 2000m CPU
- Grafana: 2 replicas, 2Gi RAM, 1000m CPU
- Log retention: 90 days

**Configuration:**
```bash
./scripts/deploy-prod-enterprise.sh
```

## 📊 Resource Comparison

| Component | Dev | Prod | Multiplier |
|-----------|-----|------|------------|
| EKS Nodes | 3 | 6 | 2x |
| Spot Max | 5 | 20 | 4x |
| Prometheus RAM | 512Mi | 4Gi | 8x |
| Prometheus CPU | 500m | 2000m | 4x |
| Grafana RAM | 256Mi | 2Gi | 8x |
| Grafana CPU | 250m | 1000m | 4x |
| Replicas | 1 | 2-3 | 2-3x |

## 🛡️ Security
Both environments have identical security:
- Same compliance standards
- Same security policies
- Same encryption
- Same monitoring

## 💰 Cost Optimization
- **Dev**: Optimized for cost (~$200/month)
- **Prod**: Optimized for performance (~$800/month)
- **Spot savings**: 60-90% on compute costs# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
