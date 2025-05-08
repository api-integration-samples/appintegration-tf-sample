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
variable "storage_bucket_location" {
  description = "Storage bucket location - a region, or US, EU, or ASIA"
  default     = "EU"
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
module "enabled_google_apis" {
  source = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id = var.project_id
  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "secretmanager.googleapis.com",
    "integrations.googleapis.com",
    "connectors.googleapis.com",
    "aiplatform.googleapis.com",
  ]
  disable_services_on_destroy = false
}

// Storage Bucket
resource "google_storage_bucket" "int-bucket" {
  count = var.use_storage ? 1 : 0
  name = var.storage_bucket_name
  project = module.enabled_google_apis.project_id
  location = var.storage_bucket_location
  uniform_bucket_level_access = true
}

// Application Integration Service
resource "google_integrations_client" "integration_region" {
  project = module.enabled_google_apis.project_id
  depends_on = [ module.enabled_google_apis ]
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
  project = module.enabled_google_apis.project_id
  depends_on = [ module.enabled_google_apis ]
  secret_id = "salesforce_password"
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
  project = module.enabled_google_apis.project_id
  depends_on = [ module.enabled_google_apis ]
  secret_id = "salesforce_security_token"
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
  depends_on = [module.enabled_google_apis]
  count    = var.use_vertexai ? 1 : 0
  project = module.enabled_google_apis.project_id
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

  timeouts {
    create = "60m"
    update = "60m"
  }  
}

// Google Translate Connector
resource "google_integration_connectors_connection" "google-translate-connector" {
  name     = "google-translate-connector"
  depends_on = [module.enabled_google_apis, google_integration_connectors_connection.vertex-connector]
  count    = var.use_google_translate ? 1 : 0
  project = module.enabled_google_apis.project_id
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

  timeouts {
    create = "60m"
    update = "60m"
  }
}

// Google Cloud Storage Connector
resource "google_integration_connectors_connection" "cloud-storage-connector" {
  name = "cloud-storage-connector"
  depends_on = [module.enabled_google_apis, google_integration_connectors_connection.google-translate-connector]
  count = var.use_storage ? 1 : 0
  project = module.enabled_google_apis.project_id
  location = var.region
  connector_version = "projects/${var.project_id}/locations/global/providers/gcp/connectors/gcs/versions/1"
  description = "Connector for Cloud Storage."
  
  config_variable {
    key = "project_id"
    string_value =  var.project_id
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

  timeouts {
    create = "60m"
    update = "60m"
  }
}

// Salesforce Connector
resource "google_integration_connectors_connection" "salesforce-connector" {
  name = "salesforce-connector"
  depends_on = [module.enabled_google_apis, google_integration_connectors_connection.cloud-storage-connector]
  count = var.use_salesforce ? 1 : 0
  project = module.enabled_google_apis.project_id
  location = var.region
  connector_version = "projects/${var.project_id}/locations/global/providers/salesforce/connectors/salesforce/versions/1"
  description = "Connector for Salesforce."
  
  config_variable {
    key = "project_id"
    string_value =  var.project_id
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

  timeouts {
    create = "60m"
    update = "60m"
  }
}