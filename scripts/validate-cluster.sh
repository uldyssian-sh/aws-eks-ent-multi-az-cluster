#!/bin/bash

set -e

if ! NODES=$(kubectl get nodes --no-headers | grep Ready | wc -l | tr -d ' '); then
  echo "❌ Failed to get nodes"
  exit 1
fi

if ! PODS=$(kubectl get pods -n kube-system --no-headers | grep Running | wc -l | tr -d ' '); then
  echo "❌ Failed to get pods"
  exit 1
fi
echo "✅ "$NODES" nodes, "$PODS" pods"