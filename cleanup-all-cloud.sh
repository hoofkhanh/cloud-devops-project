#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-us-central1}"
ZONE="${ZONE:-us-central1-a}"

NETWORK="${NETWORK:-my-network}"
SUBNET="${SUBNET:-my-subnet-1}"
CLUSTER="${CLUSTER:-my-cluster}"
REPO="${REPO:-my-repo}"
BUILD_SA="${BUILD_SA:-cloud-build-runner}"
BUILD_BUCKET="${BUILD_BUCKET:-${PROJECT_ID}-build-source}"
SQL_INSTANCE="${SQL_INSTANCE:-my-sql-instance}"
SQL_SA="${SQL_SA:-cloudsql-client}"
NAMESPACE="${NAMESPACE:-my-ns}"
HELM_DIR="${HELM_DIR:-$HOME/cloud-devops-project/helm}"

if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
  echo "ERROR: No active GCP project."
  echo "Run: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

# Step 1: Run the separate Helm/Kubernetes uninstallation script FIRST.
RUN_UNINSTALL="${HELM_DIR}/run-uninstallation.sh"
if [[ -f "${RUN_UNINSTALL}" ]]; then
  echo
  echo "Step 1: Running ${RUN_UNINSTALL}"
  bash "${RUN_UNINSTALL}"
else
  echo "ERROR: Required script not found: ${RUN_UNINSTALL}"
  echo "Place run-uninstallation.sh in the helm folder before continuing."
  exit 1
fi

# Step 2: Delete GKE cluster (also removes remaining cluster-scoped K8s resources).
echo
echo "Step 2: Delete GKE cluster"
if gcloud container clusters describe "${CLUSTER}" \
  --zone="${ZONE}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud container clusters delete "${CLUSTER}" \
    --zone="${ZONE}" --project="${PROJECT_ID}" --quiet
else
  echo "Cluster not found; skipping."
fi

# Step 3: Delete Cloud SQL (permanent data loss).
echo
echo "Step 3: Delete Cloud SQL instance"
if gcloud sql instances describe "${SQL_INSTANCE}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud sql instances delete "${SQL_INSTANCE}" \
    --project="${PROJECT_ID}" --quiet
else
  echo "Cloud SQL instance not found; skipping."
fi

# Step 4: Delete Artifact Registry repository and all image tags/digests in it.
echo
echo "Step 4: Delete Artifact Registry repository"
if gcloud artifacts repositories describe "${REPO}" \
  --location="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud artifacts repositories delete "${REPO}" \
    --location="${REGION}" --project="${PROJECT_ID}" --quiet
else
  echo "Repository not found; skipping."
fi

# Step 5: Delete Cloud Build staging/log bucket and all its objects.
echo
echo "Step 5: Delete build bucket and contents"
if gcloud storage buckets describe "gs://${BUILD_BUCKET}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud storage rm --recursive "gs://${BUILD_BUCKET}/**" || {
    echo "WARNING: Could not remove every object from gs://${BUILD_BUCKET}."
    echo "Check bucket retention policies/holds and retry manually."
  }
  gcloud storage buckets delete "gs://${BUILD_BUCKET}" \
    --project="${PROJECT_ID}" --quiet
else
  echo "Build bucket not found; skipping."
fi

# Step 6: Remove the project's specific IAM grants added for these service accounts.
echo
echo "Step 6: Remove IAM bindings and service accounts"
BUILD_SA_EMAIL="${BUILD_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
SQL_SA_EMAIL="${SQL_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "${BUILD_SA_EMAIL}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud projects remove-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${BUILD_SA_EMAIL}" \
    --role="roles/logging.logWriter" --quiet || true

  gcloud iam service-accounts delete "${BUILD_SA_EMAIL}" \
    --project="${PROJECT_ID}" --quiet
else
  echo "Build service account not found; skipping."
fi

if gcloud iam service-accounts describe "${SQL_SA_EMAIL}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  # Remove the conditional Cloud SQL Client grant if present.
  gcloud projects remove-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SQL_SA_EMAIL}" \
    --role="roles/cloudsql.client" \
    --condition="expression=resource.name == 'projects/${PROJECT_ID}/instances/${SQL_INSTANCE}' && resource.service == 'sqladmin.googleapis.com',title=OnlyMySQLInstance,description=Allow Cloud SQL connection to the specified instance" \
    --quiet || true

  gcloud iam service-accounts delete "${SQL_SA_EMAIL}" \
    --project="${PROJECT_ID}" --quiet
else
  echo "Cloud SQL service account not found; skipping."
fi

# Step 7: Disconnect Service Networking peering before deleting its range/VPC.
echo
echo "Step 7: Remove Service Networking peering and reserved range"
PEERING_EXISTS="false"
if gcloud compute networks peerings list \
  --network="${NETWORK}" --project="${PROJECT_ID}" \
  --format='value(name)' 2>/dev/null | grep -qx 'servicenetworking-googleapis-com'; then
  PEERING_EXISTS="true"
fi

if [[ "${PEERING_EXISTS}" == "true" ]]; then
  gcloud services vpc-peerings delete \
    --service=servicenetworking.googleapis.com \
    --network="${NETWORK}" \
    --project="${PROJECT_ID}" --quiet || {
      echo "WARNING: Could not remove Service Networking peering."
      echo "VPC deletion may fail until the peering is removed."
    }
fi

RANGE_NAME="google-managed-services-${NETWORK}"
if gcloud compute addresses describe "${RANGE_NAME}" \
  --global --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud compute addresses delete "${RANGE_NAME}" \
    --global --project="${PROJECT_ID}" --quiet || true
fi

# Step 8: Delete subnet then VPC.
echo
echo "Step 8: Delete subnet and VPC"
if gcloud compute networks subnets describe "${SUBNET}" \
  --region="${REGION}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud compute networks subnets delete "${SUBNET}" \
    --region="${REGION}" --project="${PROJECT_ID}" --quiet
else
  echo "Subnet not found; skipping."
fi

if gcloud compute networks describe "${NETWORK}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud compute networks delete "${NETWORK}" \
    --project="${PROJECT_ID}" --quiet || {
      echo "WARNING: VPC was not deleted. Check for other resources still attached to it."
    }
else
  echo "VPC not found; skipping."
fi

# Step 9: Delete GitHub Actions Workload Identity Federation
# echo
# echo "Step 9: Delete GitHub Actions WIF resources"

# GITHUB_REPO="${GITHUB_REPO:-hoofkhanh/cloud-devops-project}"
# WIF_POOL="${WIF_POOL:-github-pool}"
# WIF_PROVIDER="${WIF_PROVIDER:-github-provider}"

# PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" \
#   --format="value(projectNumber)")

# if gcloud iam service-accounts describe "${BUILD_SA_EMAIL}" \
#   --project="${PROJECT_ID}" >/dev/null 2>&1; then

#   gcloud iam service-accounts remove-iam-policy-binding \
#     "${BUILD_SA_EMAIL}" \
#     --project="${PROJECT_ID}" \
#     --role="roles/iam.workloadIdentityUser" \
#     --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL}/attribute.repository/${GITHUB_REPO}" \
#     --quiet || echo "No matching impersonation binding to remove."
# fi

# if gcloud iam workload-identity-pools providers describe \
#   "${WIF_PROVIDER}" \
#   --project="${PROJECT_ID}" \
#   --location="global" \
#   --workload-identity-pool="${WIF_POOL}" >/dev/null 2>&1; then

#   gcloud iam workload-identity-pools providers delete \
#     "${WIF_PROVIDER}" \
#     --project="${PROJECT_ID}" \
#     --location="global" \
#     --workload-identity-pool="${WIF_POOL}" \
#     --quiet
# else
#   echo "GitHub provider not found; skipping."
# fi

# if gcloud iam workload-identity-pools describe \
#   "${WIF_POOL}" \
#   --project="${PROJECT_ID}" \
#   --location="global" >/dev/null 2>&1; then

#   gcloud iam workload-identity-pools delete "${WIF_POOL}" \
#     --project="${PROJECT_ID}" \
#     --location="global" \
#     --quiet
# else
#   echo "GitHub pool not found; skipping."
# fi

echo
echo "============================================================"
echo "Cleanup finished (some resources may have been skipped)."
echo "Review warnings above and verify remaining resources."
echo "Project APIs were intentionally left enabled."
echo "============================================================"
