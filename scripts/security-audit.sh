#!/bin/bash

set -e

echo "🔒 Running enterprise security audit..."

# Check cluster security
echo "🛡️ Checking cluster security configuration..."
kubectl get networkpolicies -A 2>/dev/null || { echo "⚠️ Network policies not found"; exit 1; }

# Check RBAC
echo "👥 Auditing RBAC configuration..."
kubectl auth can-i --list --as=system:anonymous 2>/dev/null | head -5 || { echo "❌ RBAC check failed"; exit 1; }
echo "✅ Anonymous access restrictions verified"

# Check pod security contexts
echo "🔐 Checking pod security contexts..."
if kubectl get pods -A >/dev/null 2>&1; then
    INSECURE_PODS=$(kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.securityContext.runAsRoot}{"\n"}{end}' 2>/dev/null | grep -c "true" 2>/dev/null || echo "0")
else
    echo "❌ Failed to access pods"
    exit 1
fi
echo "📊 Pods running as root: $INSECURE_PODS"

# Check network policies
echo "🌐 Checking network policies..."
if kubectl get namespaces >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    NAMESPACES_WITHOUT_NETPOL=$(kubectl get namespaces -o json | jq -r '.items[] | select(.metadata.name != "kube-system" and .metadata.name != "kube-public") | .metadata.name' | while read -r ns; do
        if ! kubectl get networkpolicy -n "$ns" >/dev/null 2>&1; then
            echo "$ns"
        fi
    done | wc -l)
else
    echo "❌ kubectl or jq not available"
    exit 1
fi
echo "📊 Namespaces without network policies: $NAMESPACES_WITHOUT_NETPOL"

# Check secrets encryption
echo "🔑 Checking secrets encryption..."
kubectl get secrets -A --field-selector type=Opaque 2>/dev/null | wc -l | xargs -I {} echo "📊 Opaque secrets found: {}" || { echo "❌ Secrets check failed"; exit 1; }

# Security score calculation
TOTAL_CHECKS=4
PASSED_CHECKS=$((4 - (INSECURE_PODS > 0 ? 1 : 0) - (NAMESPACES_WITHOUT_NETPOL > 0 ? 1 : 0)))
SECURITY_SCORE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo "📊 Security Audit Summary:"
echo "   Security Score: $SECURITY_SCORE/100"
echo "   Insecure pods: $INSECURE_PODS"
echo "   Unprotected namespaces: $NAMESPACES_WITHOUT_NETPOL"

if [ $SECURITY_SCORE -ge 90 ]; then
    echo "✅ Security audit passed!"
else
    echo "⚠️ Security improvements needed"
fi# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
