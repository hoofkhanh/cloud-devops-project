terraform {
  backend "gcs" {
    bucket = "dev-devops-project-2026-terraform_state"
    prefix = "terraform/state/envs/dev"
  }
}