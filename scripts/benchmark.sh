#!/bin/bash

set -e

echo "⚡ Running Kubernetes benchmarks"

# Node performance
echo "📊 Node Performance:"
kubectl top nodes 2>/dev/null || echo "Metrics server not available"

# Pod density test
echo "📦 Pod Density:"
TOTAL_PODS=$(kubectl get pods -A --no-headers | wc -l)
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l)
if [ "$TOTAL_NODES" -gt 0 ]; then
    echo "Pods per node: $((TOTAL_PODS / TOTAL_NODES))"
else
    echo "No nodes found"
fi

# API server latency
echo "🔌 API Server Latency:"
time kubectl get nodes >/dev/null

# etcd performance
echo "💾 etcd Health:"
kubectl get --raw /healthz/etcd 2>/dev/null || echo "etcd health check not available"

# Network performance
echo "🌐 Network Performance:"
kubectl run netperf --image=networkstatic/netperf --rm -it --restart=Never -- netperf -H kubernetes.default.svc.cluster.local 2>/dev/null || echo "Network test skipped"

# Storage performance
echo "💿 Storage Performance:"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: storage-test
spec:
  containers:
  - name: test
    image: busybox
    command: ['sh', '-c', 'dd if=/dev/zero of=/tmp/test bs=1M count=100; rm /tmp/test']
  restartPolicy: Never
EOF

kubectl wait --for=condition=completed pod/storage-test --timeout=60s 2>/dev/null || echo "Storage test timeout"
kubectl delete pod storage-test --ignore-not-found

echo "✅ Benchmark completed"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
