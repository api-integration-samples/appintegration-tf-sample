// Variables 
variable "project_id" {
  description = "Project id."
  type        = string
}
variable "region" {
  description = "GCP region."
  type        = string
}
variable "bucket_name" {
  description = "Storage bucket name."
  default     = ""
  type        = string
}

// Storage Bucket
resource "google_storage_bucket" "int-bucket" {
 count         = var.bucket_name == "" ? 0 : 1
 name          = var.bucket_name
 project       = var.project_id
 location      = "EU"
 storage_class = "STANDARD"

 uniform_bucket_level_access = true
}

// Application Integration Service
resource "google_integrations_client" "integration_region" {
  project = var.project_id
  location = var.region
}

// Service Account
resource "google_service_account" "int-service" {
  project = var.project_id
  account_id = "int-service"
  display_name = "Integration Service Account"
}
// Service Account Roles
resource "google_project_iam_member" "int-service-storage-admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.int-service.email}"
}
resource "google_project_iam_member" "int-service-secret-accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.int-service.email}"
}

// Vertex AI Connector
resource "google_integration_connectors_connection" "vertex-connector" {
  name     = "vertex-connector"
  project = var.project_id
  location = var.region
  connector_version = "projects/${var.project_id}/locations/global/providers/gcp/connectors/vertexai/versions/1"
  description = "Connector for Vertex AI"
  
  node_config {
    min_node_count = 1
    max_node_count = 1
  }

  auth_config {
    auth_type = "AUTH_TYPE_UNSPECIFIED"
    auth_key = "service_account"
    user_password {
      username = ""
    }
  }

  service_account = "${google_service_account.int-service.email}"

  destination_config {
    key = "base_url"
    destination {
      host = "https://${var.region}-aiplatform.googleapis.com/"
    }
  }

  log_config {
    enabled = true
  }
}

// Google Translate Connector
resource "google_integration_connectors_connection" "google-translate-connector" {
  name     = "google-translate-connector"
  project = var.project_id
  location = var.region
  connector_version = "projects/${var.project_id}/locations/global/providers/gcp/connectors/cloudtranslation/versions/1"
  description = "Connector for Google Translate"
  
  node_config {
    min_node_count = 1
    max_node_count = 1
  }

  auth_config {
    auth_type = "AUTH_TYPE_UNSPECIFIED"
    auth_key = "service_account"
    user_password {
      username = ""
    }
  }

  service_account = "${google_service_account.int-service.email}"

  log_config {
    enabled = true
  }
}

// Google Cloud Storage Connector
resource "google_integration_connectors_connection" "cloud-storage-connector" {
  name                = "cloud-storage-connector"
  count               = var.bucket_name == "" ? 0 : 1
  project             = var.project_id
  location            = var.region
  connector_version   = "projects/${var.project_id}/locations/global/providers/gcp/connectors/gcs/versions/1"
  description = "Connector for Cloud Storage"
  
  config_variable {
    key               = "project_id"
    string_value      =  var.project_id
  }

  node_config {
    min_node_count = 1
    max_node_count = 1
  }

  auth_config {
    auth_type = "USER_PASSWORD"
    user_password {
      username = ""
    }
  }

  service_account = "${google_service_account.int-service.email}"

  log_config {
    enabled = true
  }
}