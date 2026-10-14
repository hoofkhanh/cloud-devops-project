
#!/bin/bash
set -e

export PROJECT_ID="devops-project-510903"
export GSA_EMAIL="cloudsql-client"

kubectl apply -f namespace.yaml
envsubst < service-account.yaml | kubectl apply -f -
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

echo "Chạy r"
JOB=$(kubectl apply -f create-table-job.yaml \
  -o jsonpath='{.metadata.name}')
kubectl wait --for=condition=complete "job/$JOB" \
  -n my-ns --timeout=30s || true
kubectl delete job mysql-init -n my-ns
echo "Xong r"

kubectl apply -f service-1.yaml
kubectl apply -f service-2.yaml
kubectl apply -f deployment-1.yaml
kubectl apply -f deployment-2.yaml
kubectl apply -f gateway.yaml
kubectl apply -f http-route.yaml
