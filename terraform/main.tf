# Download the Google Cloud provider
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Upload the Terraform .tfstate file to Google Cloud Storage
# See https://console.cloud.google.com/storage/browser/books-terraform-state
terraform {
  backend "gcs" {
    bucket = "books-terraform-state"
  }
}

# Google Cloud Storage bucket where the Terraform .tfstate file is stored
resource "google_storage_bucket" "terraform_state_storage_bucket" {
  name     = "books-terraform-state"
  location = "US"
}

variable "google_cloud_project_id" {
  description = "The ID of the Google Cloud project where the various Google Cloud resources will be created."
  type        = string
}

variable "books_image_tag" {
  description = "The tag of the Books Docker image. It looks like 'abcde123' representing the short SHA of the commit."
  type        = string
}

provider "google" {
  project = var.google_cloud_project_id
}

# Before deploying certain Google Cloud resources, we need to first
# enable Google Cloud APIs associated with those resources.
module "enable_google_cloud_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 15.0"
  disable_services_on_destroy = false
  project_id                  = var.google_cloud_project_id
  activate_apis = [
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "run.googleapis.com",
  ]
}

# Service account that runs Cloud Build triggers.
resource "google_service_account" "build_service_account" {
  account_id   = "books-cloud-build"
  display_name = "Cloud Build Service Account"
}

# The Cloud Build service account needs to be able to write to the Google Cloud Logging.
resource "google_project_iam_member" "build_service_account_logging_logwriter" {
  project = var.google_cloud_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

# The Cloud Build service account needs to be able to push images to the Artifact Registry.
resource "google_project_iam_member" "build_service_account_artifactregistry_writer" {
  project = var.google_cloud_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

# The Cloud Build service account needs to be able to view Google Cloud resources when applying Terraform.
resource "google_project_iam_member" "build_service_account_viewer" {
  project = var.google_cloud_project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

# The Cloud Build service account needs to be able to write to the Terraform state stored in Google Cloud Storage.
resource "google_project_iam_member" "build_service_account_storage_object_user" {
  project = var.google_cloud_project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

# The Cloud Build service account needs to be able to deploy to Cloud Run
# and configure the Cloud Run service's invoker_iam_disabled annotation
# (which requires roles/run.admin).
resource "google_project_iam_member" "build_service_account_run_admin" {
  project = var.google_cloud_project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.build_service_account.email}"
}

# The Cloud Build service account needs to be able to act as the Cloud Run service's
# service account, in order to redeploy the service.
resource "google_service_account_iam_binding" "build_service_account_run_service_account_user" {
  service_account_id = google_service_account.books_cloud_run_service_service_account.id
  role               = "roles/iam.serviceAccountUser"
  members            = ["serviceAccount:${google_service_account.build_service_account.email}"]
}

# Cloud Build trigger that builds and redeploy the web application
# every time a commit is made to the main branch of the GitHub repository.
resource "google_cloudbuild_trigger" "build_trigger_main_branch_build_and_deploy" {
  project         = var.google_cloud_project_id
  name            = "books-main-branch-build-and-deploy"
  description     = "This trigger builds and redeploys the web application when a commit is made to the main branch of the GitHub repository."
  filename        = "terraform/build-and-deploy.yaml"
  service_account = google_service_account.build_service_account.id
  github {
    owner = "NimJay"
    name  = "books"
    push {
      branch = "^main$"
    }
  }
  depends_on = [
    module.enable_google_cloud_apis,
  ]
}

# Artifact Registry Docker container repository where we store images of the Books web application
resource "google_artifact_registry_repository" "docker_container_registry_repository" {
  project       = var.google_cloud_project_id
  location      = "us-central1"
  repository_id = "books-docker-containers"
  description   = "Docker container registry for Books."
  format        = "DOCKER"
  depends_on = [
    module.enable_google_cloud_apis,
  ]
}

# Cloud Run service that runs the Books container image
resource "google_cloud_run_service" "books_cloud_run_service" {
  project  = var.google_cloud_project_id
  name     = "books"
  location = "us-central1"
  template {
    spec {
      service_account_name = google_service_account.books_cloud_run_service_service_account.email
      containers {
        image = "us-central1-docker.pkg.dev/${var.google_cloud_project_id}/books-docker-containers/books:${var.books_image_tag}"
        env {
          name  = "GOOGLE_CLOUD_PROJECT_ID"
          value = var.google_cloud_project_id
        }
        ports {
          container_port = 3000
        }
      }
    }
  }
  metadata {
    annotations = {
      # Allow public access to the Cloud Run service.
      "run.googleapis.com/invoker-iam-disabled" = "true"
    }
  }
  depends_on = [
    module.enable_google_cloud_apis,
  ]
}

# Service account for the Cloud Run service running Books
resource "google_service_account" "books_cloud_run_service_service_account" {
  account_id   = "books-cloud-run-service"
  display_name = "Books Cloud Run Service Service Account"
}

# Map books.reexpose.org to the Books Cloud Run service.
# resource "google_cloud_run_domain_mapping" "default" {
#   location = "us-central1"
#   name     = "books.reexpose.org"
#   metadata {
#     namespace = var.google_cloud_project_id
#   }
#   spec {
#     route_name = google_cloud_run_service.books_cloud_run_service.name
#   }
# }
