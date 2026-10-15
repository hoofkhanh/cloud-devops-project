#!/bin/bash

NAMESPACE="my-ns"
export PROJECT_ID="devops-project-510903"
export GSA_EMAIL="cloudsql-client"

set -e

read -rp "Enter backend hostname: " HOSTNAME
HOSTNAME=${HOSTNAME:-hoofkhanh.com}


echo
echo "==========================INSTALL HELM============================"
helm upgrade --install dev . \
  -n "$NAMESPACE" \
  --create-namespace \
  --set gateway.host="$HOSTNAME" \
  --set GSA_EMAIL="$GSA_EMAIL" \
  --set PROJECT_ID="$PROJECT_ID"

echo "==========================INSTALL HELM============================"
echo

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

# config the ingress host into the /etc/hosts file
# GATEWAY_ADDRESS=$(kubectl get gateway dev-cloud-devops-project-app-gateway \
#   -n my-ns -o jsonpath='{.status.addresses[0].value}')
# ESCAPED_IP=$(printf '%s\n' "$GATEWAY_ADDRESS" | sed 's/\./\\./g')

# if grep -q "^${ESCAPED_IP}" /etc/hosts; then
#     sudo sed -i "s/^${ESCAPED_IP}.*$/${GATEWAY_ADDRESS} $HOSTNAME/" /etc/hosts
# else
#     sudo sh -c "echo '$GATEWAY_ADDRESS $HOSTNAME' >> /etc/hosts"
# fi

# echo "url: http://$HOSTNAME"


GATEWAY_ADDRESS=$(kubectl get gateway dev-cloud-devops-project-app-gateway \
  -n my-ns -o jsonpath='{.status.addresses[0].value}')

echo "url: http://$GATEWAY_ADDRESS"