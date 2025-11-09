#!/bin/bash

set -e

CLUSTER_NAME=${1}
AWS_REGION=${2:-us-west-2}

if [ -z ""$CLUSTER_NAME"" ]; then
    echo "Usage: $0 <cluster-name> [aws-region]"
    exit 1
fi

# Wait for cluster
aws eks wait cluster-active --name "$CLUSTER_NAME" --region "$AWS_REGION" 2>/dev/null

# Install cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml >/dev/null 2>&1
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s >/dev/null 2>&1

# Install AWS Load Balancer Controller
curl -s -o v2_4_7_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.4.7/v2_4_7_full.yaml
sed -i.bak "s/your-cluster-name/"$CLUSTER_NAME"/g" v2_4_7_full.yaml
kubectl apply -f v2_4_7_full.yaml >/dev/null 2>&1

# Install EBS CSI Driver
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.19" >/dev/null 2>&1

# Install Cluster Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml >/dev/null 2>&1
kubectl patch deployment cluster-autoscaler -n kube-system -p '{"spec":{"template":{"spec":{"containers":[{"name":"cluster-autoscaler","command":["./cluster-autoscaler","--v=4","--stderrthreshold=info","--cloud-provider=aws","--skip-nodes-with-local-storage=false","--expander=least-waste","--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/'"$CLUSTER_NAME"'"]}]}}}}' >/dev/null 2>&1

# Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml >/dev/null 2>&1

# Cleanup
rm -f v2_4_7_full.yaml v2_4_7_full.yaml.bak