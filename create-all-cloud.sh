#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_ID="$(gcloud config get-value project)"
REGION="us-central1"
ZONE="us-central1-a"

NETWORK="my-network"
SUBNET="my-subnet-1"
CLUSTER="my-cluster"

POD_RANGE="gke-pods"
SERVICE_RANGE="gke-services"

REPO="my-repo"
BUILD_SA="cloud-build-runner"
BUILD_BUCKET="${PROJECT_ID}-build-source"

SQL_INSTANCE="my-sql-instance"
SQL_DB="app"
SQL_USER="khanh"

read -rsp "Enter MYSQL user password: " MYSQL_PASSWORD
echo
SQL_PASSWORD="${MYSQL_PASSWORD:?Set MYSQL_PASSWORD before running}"

read -rsp "Enter MYSQL root password: " ROOT_PASSWORD
echo
ROOT_PASSWORD="${ROOT_PASSWORD:?Set ROOT_PASSWORD before running}"

SQL_SA="cloudsql-client"
NAMESPACE="my-ns"
KSA="app-ksa"

APP_DIR="$HOME/cloud-devops-project/app"
IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/app"

echo "Project: $PROJECT_ID"
echo "Region:  $REGION"
echo "Zone:    $ZONE"

# ============================================================
# PHASE 0: ENABLE APIS
# ============================================================

gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  storage.googleapis.com \
  logging.googleapis.com \
  sqladmin.googleapis.com \
  servicenetworking.googleapis.com \
  iam.googleapis.com \
  --project="$PROJECT_ID"

# ============================================================
# PHASE 1: VPC AND SUBNET
# ============================================================

if ! gcloud compute networks describe "$NETWORK" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then

  gcloud compute networks create "$NETWORK" \
    --subnet-mode=custom \
    --project="$PROJECT_ID"
fi

if ! gcloud compute networks subnets describe "$SUBNET" \
  --region="$REGION" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then

  gcloud compute networks subnets create "$SUBNET" \
    --region="$REGION" \
    --network="$NETWORK" \
    --range=10.0.1.0/24 \
    --secondary-range="${POD_RANGE}=10.0.16.0/20,${SERVICE_RANGE}=10.0.3.0/24" \
    --project="$PROJECT_ID"
fi

# ============================================================
# PHASE 2: GKE CLUSTER AND GATEWAY API
# ============================================================

if ! gcloud container clusters describe "$CLUSTER" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then

  gcloud container clusters create "$CLUSTER" \
    --project="$PROJECT_ID" \
    --zone="$ZONE" \
    --network="$NETWORK" \
    --subnetwork="$SUBNET" \
    --num-nodes=1 \
    --enable-ip-alias \
    --cluster-secondary-range-name="$POD_RANGE" \
    --services-secondary-range-name="$SERVICE_RANGE" \
    --workload-pool="${PROJECT_ID}.svc.id.goog"
fi

# Enable Gateway API support.
gcloud container clusters update "$CLUSTER" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --gateway-api=standard

# Enable Workload Identity metadata on the default node pool.
gcloud container node-pools update default-pool \
  --cluster="$CLUSTER" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --workload-metadata=GKE_METADATA

gcloud container clusters get-credentials "$CLUSTER" \
  --zone="$ZONE" \
  --project="$PROJECT_ID"

# ============================================================
# PHASE 3: ARTIFACT REGISTRY
# ============================================================

if ! gcloud artifacts repositories describe "$REPO" \
  --location="$REGION" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then

  gcloud artifacts repositories create "$REPO" \
    --repository-format=docker \
    --location="$REGION" \
    --project="$PROJECT_ID"
fi

# ============================================================
# PHASE 4: CLOUD BUILD SERVICE ACCOUNT AND STORAGE
# ============================================================

BUILD_SA_EMAIL="${BUILD_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe "$BUILD_SA_EMAIL" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then

  gcloud iam service-accounts create "$BUILD_SA" \
    --project="$PROJECT_ID"
fi

if ! gcloud storage buckets describe "gs://${BUILD_BUCKET}" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then

  gcloud storage buckets create "gs://${BUILD_BUCKET}" \
    --project="$PROJECT_ID" \
    --location="$REGION" \
    --uniform-bucket-level-access
fi

gcloud storage buckets add-iam-policy-binding "gs://${BUILD_BUCKET}" \
  --member="serviceAccount:${BUILD_SA_EMAIL}" \
  --role="roles/storage.admin" \
  --project="$PROJECT_ID" \
  --condition=None

gcloud artifacts repositories add-iam-policy-binding "$REPO" \
  --location="$REGION" \
  --project="$PROJECT_ID" \
  --member="serviceAccount:${BUILD_SA_EMAIL}" \
  --role="roles/artifactregistry.writer" \
  --condition=None

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${BUILD_SA_EMAIL}" \
  --role="roles/logging.logWriter" \
  --condition=None

# # Allow Cloud Build's service agent to use the custom build identity.
# PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" \
#   --format='value(projectNumber)')"

# gcloud projects add-iam-policy-binding "$PROJECT_ID" \
#   --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
#   --role="roles/iam.serviceAccountTokenCreator"

# gcloud iam service-accounts add-iam-policy-binding "$BUILD_SA_EMAIL" \
#   --project="$PROJECT_ID" \
#   --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
#   --role="roles/iam.serviceAccountUser"

# ============================================================
# PHASE 5: BUILD AND PUSH BOTH APPLICATION IMAGES
# ============================================================

test -f "$APP_DIR/app-1/Dockerfile" || {
  echo "Missing $APP_DIR/app-1/Dockerfile"
  exit 1
}

test -f "$APP_DIR/app-2/Dockerfile" || {
  echo "Missing $APP_DIR/app-2/Dockerfile"
  exit 1
}

gcloud builds submit "$APP_DIR/app-1" \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${BUILD_SA_EMAIL}" \
  --gcs-source-staging-dir="gs://${BUILD_BUCKET}/source" \
  --gcs-log-dir="gs://${BUILD_BUCKET}/logs" \
  --tag="${IMAGE_BASE}:v1"

gcloud builds submit "$APP_DIR/app-2" \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --service-account="projects/${PROJECT_ID}/serviceAccounts/${BUILD_SA_EMAIL}" \
  --gcs-source-staging-dir="gs://${BUILD_BUCKET}/source" \
  --gcs-log-dir="gs://${BUILD_BUCKET}/logs" \
  --tag="${IMAGE_BASE}:v2"

# ============================================================
# PHASE 6: CLOUD SQL PRIVATE IP
# ============================================================

if ! gcloud compute addresses list \
  --global \
  --project="$PROJECT_ID" \
  --filter="name=google-managed-services-${NETWORK}" \
  --format='value(name)' | grep -q .; then

  gcloud compute addresses create "google-managed-services-${NETWORK}" \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --network="$NETWORK" \
    --project="$PROJECT_ID"
fi

if ! gcloud compute networks peerings list \
  --network="$NETWORK" \
  --project="$PROJECT_ID" \
  --format='value(name)' | grep -q '^servicenetworking-googleapis-com$'; then

  gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --network="$NETWORK" \
    --ranges="google-managed-services-${NETWORK}" \
    --project="$PROJECT_ID"
fi

if ! gcloud sql instances describe "$SQL_INSTANCE" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then

  gcloud sql instances create "$SQL_INSTANCE" \
    --project="$PROJECT_ID" \
    --database-version=MYSQL_8_0 \
    --region="$REGION" \
    --cpu=2 \
    --memory=7680MB \
    --root-password="$ROOT_PASSWORD"
fi

# Configure private IP. This removes the instance's public IP.
gcloud sql instances patch "$SQL_INSTANCE" \
  --project="$PROJECT_ID" \
  --network="projects/${PROJECT_ID}/global/networks/${NETWORK}" \
  --no-assign-ip

if ! gcloud sql users list \
  --instance="$SQL_INSTANCE" \
  --project="$PROJECT_ID" \
  --format='value(name)' | grep -qx "$SQL_USER"; then

  gcloud sql users create "$SQL_USER" \
    --instance="$SQL_INSTANCE" \
    --password="$SQL_PASSWORD" \
    --project="$PROJECT_ID"
else
  gcloud sql users set-password "$SQL_USER" \
    --instance="$SQL_INSTANCE" \
    --password="$SQL_PASSWORD" \
    --project="$PROJECT_ID"
fi

# ============================================================
# PHASE 7: WORKLOAD IDENTITY FEDERATION FOR GKE
# ============================================================

# gcloud container clusters update "$CLUSTER" \
#   --zone="$ZONE" \
#   --project="$PROJECT_ID" \
#   --workload-pool="${PROJECT_ID}.svc.id.goog"

SQL_SA_EMAIL="${SQL_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe "$SQL_SA_EMAIL" \
  --project="$PROJECT_ID" >/dev/null 2>&1; then

  gcloud iam service-accounts create "$SQL_SA" \
    --project="$PROJECT_ID"
fi

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SQL_SA_EMAIL}" \
  --role="roles/cloudsql.client" \
  --condition="expression=resource.name == 'projects/${PROJECT_ID}/instances/${SQL_INSTANCE}' && resource.service == 'sqladmin.googleapis.com',title=OnlyMySQLInstance,description=Allow Cloud SQL connection to the specified instance"
  
gcloud iam service-accounts add-iam-policy-binding "$SQL_SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${NAMESPACE}/${KSA}]" \
  --condition=None

# ============================================================
# PHASE 8: GKE IMAGE PULL PERMISSION
# ============================================================

NODE_NAME=$(kubectl get nodes | awk 'NR==2 {print $1}')

NODE_SA="$(gcloud compute instances describe "$NODE_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --format='value(serviceAccounts[0].email)')"

gcloud artifacts repositories add-iam-policy-binding "$REPO" \
  --location="$REGION" \
  --project="$PROJECT_ID" \
  --member="serviceAccount:${NODE_SA}" \
  --role="roles/artifactregistry.reader" \
  --condition=None

# ============================================================
# PHASE 9: CREATE WIP AND PROVIDER
# ============================================================

# Configuration
GITHUB_REPO="hoofkhanh/cloud-devops-project"
POOL_ID="github-pool"
PROVIDER_ID="github-provider"
SA_EMAIL="${BUILD_SA}@${PROJECT_ID}.iam.gserviceaccount.com"


# Get GCP project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" \
  --format="value(projectNumber)")

# Create GitHub Workload Identity Pool
gcloud iam workload-identity-pools create "$POOL_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create GitHub OIDC Provider
gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_ID" \
  --display-name="GitHub Actions Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository == '${GITHUB_REPO}'"

# Allow this GitHub repository to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_REPO}" \
  --quiet

# 4. Get provider resource name
GCP_WIF_PROVIDER=$(gcloud iam workload-identity-pools providers describe \
  "$PROVIDER_ID" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_ID" \
  --format="value(name)")

echo "GCP_WIF_PROVIDER: ${GCP_WIF_PROVIDER}"

# ============================================================
# PHASE 10: HELM AND GATEWAY API CHECKS
# ============================================================

cd "$HOME/cloud-devops-project/helm"
./run-installation.sh "$ROOT_PASSWORD" "$SQL_PASSWORD"



echo
echo "========== SETUP COMPLETE =========="
