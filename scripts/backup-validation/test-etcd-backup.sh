#!/bin/bash
set -e
echo "🔍 Testing etcd backup..."
kubectl get pods -n kube-system -l component=etcd --no-headers | wc -l | xargs -I {} echo "etcd pods: {}"
aws backup list-backup-jobs --query 'BackupJobs[?State==`COMPLETED`]' --output text | wc -l | xargs -I {} echo "Completed backups: {}"
echo "✅ etcd backup test completed"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
