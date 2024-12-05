terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  
  backend "gcs" {
    bucket = "calculator-tf-state"
    prefix = "state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "calculator_env" {
  source = "./modules/calculator"
  
  environment     = var.environment
  project_id      = var.project_id
  region         = var.region
  function_source = "../cloud-function"
}