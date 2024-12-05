resource "google_cloudfunctions_function" "calculator_function" {
  name        = "calculator-${var.environment}"
  runtime     = "nodejs18"
  
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_archive.name
  
  trigger_http = true
  entry_point  = "add"

  environment_variables = {
    ENVIRONMENT = var.environment
  }
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-function-${var.environment}"
  location = var.region
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "function-${timestamp()}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = var.function_source
}

resource "google_api_gateway_api" "api" {
  api_id = "calculator-api-${var.environment}"
}

resource "google_api_gateway_api_config" "api_config" {
  api = google_api_gateway_api.api.api_id
  api_config_id = "calculator-config-${var.environment}"

  openapi_documents {
    document {
      path = "spec.yaml"
      contents = base64encode(<<-EOF
        swagger: '2.0'
        info:
          title: Calculator API
          version: 1.0.0
        paths:
          /add:
            post:
              x-google-backend:
                address: ${google_cloudfunctions_function.calculator_function.https_trigger_url}
              responses:
                '200':
                  description: Success
        EOF
      )
    }
  }
  gateway_config {
    backend_config {
      google_service_account = google_service_account.gateway_account.email
    }
  }
}

resource "google_service_account" "gateway_account" {
  account_id   = "gateway-sa-${var.environment}"
  display_name = "API Gateway Service Account ${var.environment}"
}