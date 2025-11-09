#!/bin/bash
set -e
echo "💾 Testing PV backup..."
kubectl get pv --no-headers | wc -l | xargs -I {} echo "Total PVs: {}"
kubectl get pv -o jsonpath='{range .items[*]}{.metadata.annotations.backup\.kubernetes\.io/enabled}{"\n"}{end}' | grep -c "true" || echo "0" | xargs -I {} echo "Backup-enabled PVs: {}"
echo "✅ PV backup test completed"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
