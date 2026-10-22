#!/bin/bash

NAMESPACE="my-ns"
export PROJECT_ID="devops-project-510903"
export GSA_EMAIL="cloudsql-client"

set -e

# read -rp "Enter backend hostname: " HOSTNAME
# HOSTNAME=${HOSTNAME:-hoofkhanh.com}

MYSQL_ROOT_PASSWORD="${1:-}"
MYSQL_PASSWORD="${2:-}"
SMTP_USERNAME="${3:-hotuankhanh20112016@gmail.com}"
SMTP_PASSWORD="${4:-}"

if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
  read -rsp "Enter your MySQL root password: " MYSQL_ROOT_PASSWORD
  echo
fi

if [[ -z "$MYSQL_PASSWORD" ]]; then
  read -rsp "Enter your MySQL user password: " MYSQL_PASSWORD
  echo
fi

if [[ -z "$SMTP_PASSWORD" ]]; then
  read -rsp "Enter app passwrod of gmail: " SMTP_PASSWORD
  echo
fi

: "${MYSQL_ROOT_PASSWORD:?Required to enter MYSQL_ROOT_PASSWORD}"
: "${MYSQL_PASSWORD:?Required to enter MYSQL_PASSWORD}"
: "${SMTP_PASSWORD:?Required to enter SMTP_PASSWORD}"

echo
echo "==========================INSTALL HELM============================"
helm upgrade --install dev . \
  -n "$NAMESPACE" \
  --create-namespace \
  --set GSA_EMAIL="$GSA_EMAIL" \
  --set PROJECT_ID="$PROJECT_ID" \
  --set MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  --set MYSQL_PASSWORD="$MYSQL_PASSWORD" \
  --set SMTP_USERNAME="$SMTP_USERNAME" \
  --set SMTP_PASSWORD="$SMTP_PASSWORD"
  # --set gateway.host="$HOSTNAME" \

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

JOB=$(
  helm template dev . \
  -s templates/create-table-job.yaml \
  -n my-ns \
  | kubectl create --dry-run=client -f - -o jsonpath='{.metadata.name}'
)
kubectl wait --for=condition=complete "job/$JOB" \
  -n my-ns --timeout=60s || true
kubectl delete job $JOB -n my-ns