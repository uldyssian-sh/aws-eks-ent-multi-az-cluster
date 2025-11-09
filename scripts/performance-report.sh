#!/bin/bash

set -e

echo "🚀 Generating performance report..."

# Cluster health check
echo "🏥 Cluster health:"
kubectl get componentstatuses 2>/dev/null || echo "  Component status not available"

# Node readiness
echo "📊 Node status:"
kubectl get nodes --no-headers | awk '{print $2}' | sort | uniq -c | while read count status; do
    echo "  $status: $count nodes"
done

# Pod status summary
echo "🎯 Pod status summary:"
kubectl get pods -A --no-headers | awk '{print $4}' | sort | uniq -c | while read count status; do
    echo "  $status: $count pods"
done

# Resource usage
echo "📈 Resource usage (if metrics available):"
if kubectl top nodes >/dev/null 2>&1; then
    echo "  Node resource usage:"
    kubectl top nodes | tail -n +2 | while read name cpu_usage cpu_percent mem_usage mem_percent; do
        echo "    $name: CPU $cpu_percent, Memory $mem_percent"
    done
    
    echo "  Top resource consuming pods:"
    kubectl top pods -A --sort-by=cpu | head -6 | tail -n +2 | while read ns name cpu mem; do
        echo "    $ns/$name: CPU $cpu, Memory $mem"
    done
else
    echo "  Metrics server not available"
fi

# API server response time
echo "⚡ API server performance:"
START_TIME=$(date +%s%N)
kubectl get nodes >/dev/null 2>&1
END_TIME=$(date +%s%N)
RESPONSE_TIME=$(((END_TIME - START_TIME) / 1000000))
echo "  API response time: ${RESPONSE_TIME}ms"

# Deployment readiness
echo "🎯 Deployment status:"
kubectl get deployments -A --no-headers | while read ns name ready uptodate available age; do
    if [ "$ready" != "$available" ]; then
        echo "  ⚠️ $ns/$name: $ready ready, $available available"
    fi
done

# Service endpoints
echo "🌐 Service endpoints:"
SERVICES_WITHOUT_ENDPOINTS=$(kubectl get endpoints -A --no-headers | awk '$3 == "<none>" {count++} END {print count+0}')
TOTAL_SERVICES=$(kubectl get services -A --no-headers | wc -l)
echo "  Services without endpoints: $SERVICES_WITHOUT_ENDPOINTS/$TOTAL_SERVICES"

# Performance score calculation
HEALTHY_NODES=$(kubectl get nodes --no-headers | grep -c "Ready" || echo "0")
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
RUNNING_PODS=$(kubectl get pods -A --no-headers | grep -c "Running" || echo "0")
TOTAL_PODS=$(kubectl get pods -A --no-headers | wc -l)

if [ "$TOTAL_NODES" -eq 0 ]; then
  NODE_HEALTH_SCORE=0
else
  NODE_HEALTH_SCORE=$((HEALTHY_NODES * 100 / TOTAL_NODES))
fi

if [ "$TOTAL_PODS" -eq 0 ]; then
  POD_HEALTH_SCORE=0
else
  POD_HEALTH_SCORE=$((RUNNING_PODS * 100 / TOTAL_PODS))
fi
OVERALL_SCORE=$(((NODE_HEALTH_SCORE + POD_HEALTH_SCORE) / 2))

echo "📊 Performance Summary:"
echo "  Node health: $NODE_HEALTH_SCORE% ($HEALTHY_NODES/$TOTAL_NODES ready)"
echo "  Pod health: $POD_HEALTH_SCORE% ($RUNNING_PODS/$TOTAL_PODS running)"
echo "  Overall performance score: $OVERALL_SCORE/100"
echo "  API response time: ${RESPONSE_TIME}ms"

if [ $OVERALL_SCORE -ge 95 ]; then
    echo "✅ Excellent performance!"
elif [ $OVERALL_SCORE -ge 80 ]; then
    echo "✅ Good performance"
else
    echo "⚠️ Performance issues detected"
fi# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
