#!/bin/bash

set -e

echo "💰 Generating cost optimization report..."

# Get cluster info
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2 2>/dev/null || echo "unknown")
echo "📊 Cluster: $CLUSTER_NAME"

# Node cost analysis
echo "🖥️ Node cost analysis:"
kubectl get nodes -o custom-columns="NAME:.metadata.name,INSTANCE-TYPE:.metadata.labels.node\.kubernetes\.io/instance-type,ZONE:.metadata.labels.topology\.kubernetes\.io/zone" --no-headers | while read name type zone; do
    echo "  Node: $name ($type in $zone)"
done

# Spot instance usage
echo "💸 Spot instance analysis:"
SPOT_NODES=$(kubectl get nodes -l node.kubernetes.io/lifecycle=spot --no-headers 2>/dev/null | wc -l || echo "0")
TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "1")
if [ "$TOTAL_NODES" -eq 0 ]; then TOTAL_NODES=1; fi
SPOT_PERCENTAGE=$((SPOT_NODES * 100 / TOTAL_NODES))
echo "  Spot nodes: $SPOT_NODES/$TOTAL_NODES ($SPOT_PERCENTAGE%)"

# Resource utilization
echo "📈 Resource utilization:"
kubectl top nodes 2>/dev/null | tail -n +2 | while read name cpu_usage cpu_percent mem_usage mem_percent; do
    echo "  $name: CPU $cpu_percent, Memory $mem_percent"
done || echo "  Metrics server not available"

# Pod resource requests vs limits
echo "🎯 Resource efficiency:"
PODS_WITHOUT_LIMITS=$(kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.spec.containers[*].resources.limits}{"\n"}{end}' | grep -c "map\[\]" || echo "0")
TOTAL_PODS=$(kubectl get pods -A --no-headers | wc -l)
echo "  Pods without resource limits: $PODS_WITHOUT_LIMITS/$TOTAL_PODS"

# Cost optimization recommendations
echo "💡 Cost optimization recommendations:"
if [ $SPOT_PERCENTAGE -lt 50 ]; then
    echo "  ⚠️ Consider increasing spot instance usage (current: $SPOT_PERCENTAGE%)"
fi

if [ $PODS_WITHOUT_LIMITS -gt 0 ]; then
    echo "  ⚠️ Set resource limits for $PODS_WITHOUT_LIMITS pods to enable better scheduling"
fi

# Estimated monthly savings
if [ "$SPOT_PERCENTAGE" -gt 0 ]; then
    ESTIMATED_SAVINGS=$((SPOT_PERCENTAGE * 8 / 10))
    echo "📊 Estimated monthly savings with current spot usage: ~$ESTIMATED_SAVINGS%"
else
    echo "📊 Estimated monthly savings: 0% (no spot instances)"
fi

echo "✅ Cost report completed!"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
