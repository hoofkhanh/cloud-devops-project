#!/bin/bash
set -euo pipefail

NAMESPACE="my-ns"

helm uninstall dev -n "$NAMESPACE" --ignore-not-found
kubectl delete namespace "$NAMESPACE" --ignore-not-found

echo
echo "==========================VERIFY K8S RESOURCES DEPLOYED============================"
kubectl get all -n "$NAMESPACE"
echo "==========================VERIFY K8S RESOURCES DEPLOYED============================"
echo

echo
echo "==========================VERIFY HELM RESOURCES DEPLOYED============================"
helm list --namespace "$NAMESPACE"
echo "==========================VERIFY HELM RESOURCES DEPLOYED============================"
echo