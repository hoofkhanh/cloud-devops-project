
#!/bin/bash
set -e

export PROJECT_ID="devops-project-510903"
export GSA_EMAIL="cloudsql-client"

kubectl delete -f gateway.yaml
kubectl delete -f http-route.yaml
kubectl delete -f deployment-1.yaml --ignore-not-found
kubectl delete -f service-1.yaml --ignore-not-found
kubectl delete -f deployment-2.yaml --ignore-not-found
kubectl delete -f service-2.yaml --ignore-not-found
kubectl delete -f create-table-job.yaml --ignore-not-found
kubectl delete -f secret.yaml --ignore-not-found
kubectl delete -f configmap.yaml --ignore-not-found
envsubst < service-account.yaml | kubectl delete -f - --ignore-not-found
kubectl delete -f namespace.yaml --ignore-not-found
