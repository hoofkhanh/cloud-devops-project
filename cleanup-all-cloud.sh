
#!/bin/bash
set -e

PROJECT_ID="devops-project-510903"
REGION="us-central1"
ZONE="us-central1-a"

GSA_BUILD="cloud-build-runner"
GSA_SQL="cloudsql-client"
INSTANCE="my-sql-instance"
CLUSTER="my-cluster"
NETWORK="my-network"
SUBNET="my-subnet-1"
REPO="my-repo"
BUCKET="${PROJECT_ID}-build-source"

gcloud config set project "$PROJECT_ID"

# 1. Delete GKE cluster and its workloads
gcloud container clusters delete "$CLUSTER" \
  --zone="$ZONE" --quiet || true

# 2. Delete Cloud SQL instance (database data is lost)
gcloud sql instances delete "$INSTANCE" --quiet || true

# 3. Delete Artifact Registry repository
gcloud artifacts repositories delete "$REPO" \
  --location="$REGION" --quiet || true

# 4. Delete Cloud Build source bucket and its contents
gcloud storage rm --recursive --quiet \
  "gs://${BUCKET}/**" || true

gcloud storage buckets delete "gs://${BUCKET}" \
  --quiet || true

# 5. Remove Cloud SQL Client conditional IAM binding
gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${GSA_SQL}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client" \
  --condition="expression=resource.name == 'projects/${PROJECT_ID}/instances/${INSTANCE}' && resource.service == 'sqladmin.googleapis.com',title=OnlyMySQLInstance,description=Allow connection only to my-sql-instance" \
  --quiet || true

# 6. Remove Cloud Build logging IAM binding
gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${GSA_BUILD}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter" \
  --condition=None --quiet || true

# 7. Delete custom service accounts
gcloud iam service-accounts delete \
  "${GSA_SQL}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --quiet || true

gcloud iam service-accounts delete \
  "${GSA_BUILD}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --quiet || true

# 8. Delete Private Service Access peering
gcloud services vpc-peerings delete \
  --service=servicenetworking.googleapis.com \
  --network="$NETWORK" \
  --project="$PROJECT_ID" --quiet || true

# 9. Delete reserved private service range
gcloud compute addresses delete \
  google-managed-services-my-network \
  --global --quiet || true

# 10. Delete subnet and VPC
gcloud compute networks subnets delete "$SUBNET" \
  --region="$REGION" --quiet || true

gcloud compute networks delete "$NETWORK" \
  --quiet || true

echo "Cleanup commands finished."