gcloud compute networks create my-network --subnet-mode=custom
gcloud compute networks subnets create my-subnet-1 \
  --region=us-central1 \
  --network=my-network \
  --range=10.0.1.0/24 \
  --secondary-range=gke-pods=10.0.16.0/20,gke-services=10.0.3.0/24