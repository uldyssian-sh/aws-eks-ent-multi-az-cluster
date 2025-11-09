# Branch Protection Setup

## GitHub Branch Protection Rules

To protect the main branch, configure these settings in GitHub:

### Required Settings
1. **Go to**: Repository → Settings → Branches
2. **Add rule** for branch `main`
3. **Enable**:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (minimum 1)
   - ✅ Dismiss stale PR approvals when new commits are pushed
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Require conversation resolution before merging
   - ✅ Restrict pushes that create files larger than 100 MB
   - ✅ Block force pushes
   - ✅ Do not allow deletions

### Required Status Checks
- ✅ `Security Scan`
- ✅ `Terraform Validation`
- ✅ `Kubernetes Validation`
- ✅ `pre-commit` (if using pre-commit.ci)

### Advanced Settings
- ✅ Include administrators
- ✅ Allow force pushes (disabled)
- ✅ Allow deletions (disabled)

## CLI Setup (Alternative)

```bash
# Using GitHub CLI
gh api repos/uldyssian-sh/aws-eks-ent-multi-az-cluster/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["Security Scan","Terraform Validation","Kubernetes Validation"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

## Benefits
- 🛡️ Prevents accidental force pushes
- 🔒 Requires code review before merge
- ✅ Ensures all CI checks pass
- 📋 Maintains code quality standards
- 🚫 Prevents branch deletion# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
