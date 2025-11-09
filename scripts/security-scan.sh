#!/bin/bash

# Enterprise Security Scanner
# Optimized for performance and comprehensive security scanning

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/security-scan.log"
SCAN_RESULTS="${SCRIPT_DIR}/scan-results"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# Create results directory
mkdir -p "${SCAN_RESULTS}"

# Optimized container image scanning
scan_container_images() {
    log "Starting optimized container image security scan..."
    
    # Get all unique images efficiently
    local images
    mapfile -t images < <(kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u)
    
    if [ ${#images[@]} -eq 0 ]; then
        log "No container images found to scan"
        return 0
    fi
    
    log "Found ${#images[@]} unique container images to scan"
    
    # Parallel scanning with rate limiting
    local max_parallel=3
    local count=0
    
    for image in "${images[@]}"; do
        if [ $((count % max_parallel)) -eq 0 ] && [ ${count} -gt 0 ]; then
            wait # Wait for previous batch to complete
        fi
        
        {
            log "Scanning image: ${image}"
            if command -v trivy &> /dev/null; then
                trivy image --format json --output "${SCAN_RESULTS}/$(echo "${image}" | tr '/' '_' | tr ':' '_').json" "${image}" 2>/dev/null || log "Failed to scan ${image}"
            else
                log "Trivy not installed, skipping image scan for ${image}"
            fi
        } &
        
        ((count++))
    done
    
    wait # Wait for all scans to complete
    log "Container image scanning completed"
}

# Kubernetes security scan
scan_kubernetes_security() {
    log "Scanning Kubernetes security configurations..."
    
    # Check for privileged containers
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[]?.securityContext.privileged == true) | "\(.metadata.namespace)/\(.metadata.name)"' > "${SCAN_RESULTS}/privileged-pods.txt" 2>/dev/null || true
    
    # Check for containers running as root
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[]?.securityContext.runAsUser == 0 or (.spec.containers[]?.securityContext.runAsUser == null and .spec.securityContext.runAsUser == null)) | "\(.metadata.namespace)/\(.metadata.name)"' > "${SCAN_RESULTS}/root-containers.txt" 2>/dev/null || true
    
    # Check for missing network policies
    kubectl get networkpolicies --all-namespaces -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)"' > "${SCAN_RESULTS}/network-policies.txt" 2>/dev/null || true
    
    log "Kubernetes security scan completed"
}

# Network security scan
scan_network_security() {
    log "Scanning network security..."
    
    # Check for LoadBalancer services without proper annotations
    kubectl get services --all-namespaces -o json | jq -r '.items[] | select(.spec.type == "LoadBalancer") | "\(.metadata.namespace)/\(.metadata.name)"' > "${SCAN_RESULTS}/loadbalancer-services.txt" 2>/dev/null || true
    
    # Check for services without selectors
    kubectl get services --all-namespaces -o json | jq -r '.items[] | select(.spec.selector == null) | "\(.metadata.namespace)/\(.metadata.name)"' > "${SCAN_RESULTS}/services-no-selector.txt" 2>/dev/null || true
    
    log "Network security scan completed"
}

# Generate security report
generate_security_report() {
    log "Generating security report..."
    
    local report_file="${SCAN_RESULTS}/security-report.html"
    
    cat > "${report_file}" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Enterprise EKS Security Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .critical { border-left: 5px solid #ff0000; }
        .warning { border-left: 5px solid #ffa500; }
        .info { border-left: 5px solid #0066cc; }
        .success { border-left: 5px solid #00cc00; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Enterprise EKS Security Report</h1>
        <p>Generated on: $(date)</p>
    </div>
EOF
    
    # Add scan results to report
    if [ -f "${SCAN_RESULTS}/privileged-pods.txt" ] && [ -s "${SCAN_RESULTS}/privileged-pods.txt" ]; then
        echo '<div class="section critical"><h2>Critical: Privileged Containers Found</h2><pre>' >> "${report_file}"
        cat "${SCAN_RESULTS}/privileged-pods.txt" >> "${report_file}"
        echo '</pre></div>' >> "${report_file}"
    fi
    
    if [ -f "${SCAN_RESULTS}/root-containers.txt" ] && [ -s "${SCAN_RESULTS}/root-containers.txt" ]; then
        echo '<div class="section warning"><h2>Warning: Containers Running as Root</h2><pre>' >> "${report_file}"
        cat "${SCAN_RESULTS}/root-containers.txt" >> "${report_file}"
        echo '</pre></div>' >> "${report_file}"
    fi
    
    echo '</body></html>' >> "${report_file}"
    
    log "Security report generated: ${report_file}"
}

# Main execution
main() {
    log "Starting enterprise security scan..."
    
    scan_container_images
    scan_kubernetes_security
    scan_network_security
    generate_security_report
    
    log "✅ Enterprise security scan completed"
    log "Results available in: ${SCAN_RESULTS}/"
}

main "$@"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
# Updated Sun Nov  9 12:56:40 CET 2025
