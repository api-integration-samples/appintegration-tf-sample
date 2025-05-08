// Variables 
variable "project_id" {
  description = "Project id."
  type        = string
}
variable "region" {
  description = "GCP region."
  type        = string
}
variable "use_storage" {
  description = "Use Google Cloud Storage connector and create bucket."
  default     = false
  type        = bool
}
variable "storage_bucket_name" {
  description = "Storage bucket name."
  default     = ""
  type        = string
}
variable "use_vertexai" {
  description = "Use Vertex AI connector."
  default     = false
  type        = bool
}
variable "use_google_translate" {
  description = "Use Google Translate connector."
  default     = false
  type        = bool
}
variable "use_salesforce" {
  description = "Use Salesforce connector."
  default     = false
  type        = bool
}
variable "salesforce_username" {
  description = "Salesforce username."
  default     = ""
  type        = string
}
variable "salesforce_password" {
  description = "Salesforce password."
  default     = ""
  type        = string
}
variable "salesforce_security_token" {
  description = "Salesforce security token.."
  default     = ""
  type        = string
}

// Enable Project APIs
resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  timeouts {
    create = "5m"
    update = "5m"
  }

  disable_on_destroy = false
}

// Storage Bucket
resource "google_storage_bucket" "int-bucket" {
 count         = var.use_storage ? 1 : 0
 name          = var.storage_bucket_name
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
resource "google_project_iam_member" "int-service-secret-viewer" {
  project = var.project_id
  role    = "roles/secretmanager.viewer"
  member  = "serviceAccount:${google_service_account.int-service.email}"
}
resource "google_project_iam_member" "int-service-secret-accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.int-service.email}"
}

// Secrets
resource "google_secret_manager_secret" "salesforce_password" {
  count = var.use_salesforce ? 1 : 0
  depends_on = [ google_project_service.secretmanager ]
  secret_id = "salesforce_password"
  project = var.project_id
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "salesforce_password" {
  count = var.use_salesforce ? 1 : 0
  secret = google_secret_manager_secret.salesforce_password[0].id
  secret_data = var.salesforce_password
}
resource "google_secret_manager_secret" "salesforce_security_token" {
  count = var.use_salesforce ? 1 : 0
  depends_on = [ google_project_service.secretmanager ]
  secret_id = "salesforce_security_token"
  project = var.project_id
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "salesforce_security_token" {
  count = var.use_salesforce ? 1 : 0
  secret = google_secret_manager_secret.salesforce_security_token[0].id
  secret_data = var.salesforce_security_token
}

// Vertex AI Connector
resource "google_integration_connectors_connection" "vertex-connector" {
  name     = "vertex-connector"
  count    = var.use_vertexai ? 1 : 0
  project = var.project_id
  location = var.region
  connector_version = "projects/${var.project_id}/locations/global/providers/gcp/connectors/vertexai/versions/1"
  description = "Connector for Vertex AI."
  
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
  count    = var.use_google_translate ? 1 : 0
  project = var.project_id
  location = var.region
  connector_version = "projects/${var.project_id}/locations/global/providers/gcp/connectors/cloudtranslation/versions/1"
  description = "Connector for Google Translate."
  
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
  count               = var.use_storage ? 1 : 0
  project             = var.project_id
  location            = var.region
  connector_version   = "projects/${var.project_id}/locations/global/providers/gcp/connectors/gcs/versions/1"
  description = "Connector for Cloud Storage."
  
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

// Salesforce Connector
resource "google_integration_connectors_connection" "salesforce-connector" {
  name                = "salesforce-connector"
  count               = var.use_salesforce ? 1 : 0
  project             = var.project_id
  location            = var.region
  connector_version   = "projects/${var.project_id}/locations/global/providers/salesforce/connectors/salesforce/versions/1"
  description = "Connector for Salesforce."
  
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
      username = var.salesforce_username
      password {
        secret_version = google_secret_manager_secret_version.salesforce_password[0].name
      }
    }
  }

  service_account = "${google_service_account.int-service.email}"

  log_config {
    enabled = true
  }
}