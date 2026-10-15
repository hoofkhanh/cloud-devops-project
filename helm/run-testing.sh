#!/bin/bash

NAMESPACE="my-ns"

set -e

read -rp "Enter backend hostname: " HOSTNAME
HOSTNAME=${HOSTNAME:-hoofkhanh.com}

echo
echo "==========================HELM LINT============================"
helm lint .
echo "==========================HELM LINT============================"
echo

echo
echo "==========================HELM TEMPLATE============================"
helm template . \
    -n "$NAMESPACE" \
	--set gateway.host="$HOSTNAME"
echo "==========================HELM TEMPLATE============================"
echo

echo
echo "==========================INSTALL HELM============================"
helm upgrade --install dev .\
  -n "$NAMESPACE" \
  --create-namespace \
  --set gateway.host="$HOSTNAME" \
  --dry-run=server
echo "==========================INSTALL HELM============================"
echo