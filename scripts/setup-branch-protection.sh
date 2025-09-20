#!/bin/bash

set -e

echo "🛡️ Setting up branch protection for main branch"

# Create JSON payload
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Security Scan",
      "Terraform Validation", 
      "Kubernetes Validation"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

# Apply protection
echo "📋 Applying branch protection rules..."
if ! gh api repos/uldyssian-sh/aws-ent-eks-multi-az-cluster/branches/main/protection \
  --method PUT \
  --input "$TEMP_FILE"; then
  echo "❌ Failed to set branch protection"
  rm -f "$TEMP_FILE"
  exit 1
fi

echo "✅ Branch protection configured successfully!"
echo "🔒 Main branch is now protected with:"
echo "  - Required PR reviews (1+)"
echo "  - Required status checks"
echo "  - No force pushes"
echo "  - No deletions"

# Cleanup
rm -f "$TEMP_FILE"