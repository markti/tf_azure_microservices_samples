

/* yes */
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=2.13.0"
  features {}
}

provider "random" {
  version="2.2.0"
}

provider "azuread" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=0.7.0"
}


locals {
  app_name          = "testapp"
  env_name          = "dev"
  location_suffix   = "us-east"
}


module "resource_group" {
  
  source                = "github.com/markti/tf_azure_resourcegroup/base"

  name  = "${local.app_name}-${local.env_name}"
  location = "East US"
  app_name              = local.app_name
  env_name              = local.env_name

}

module "logs" {
  
  source                = "github.com/markti/tf_azure_loganalytics/workspace/base"

  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location

  app_name              = local.app_name
  env_name              = local.env_name

  name                  = "${local.app_name}-${local.env_name}-logs"

}

module "microservice_hub" {
  
  source                = "github.com/markti/tf_azure_microservices/host/premium"

  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location

  app_name              = local.app_name
  env_name              = local.env_name
  location_suffix       = local.location_suffix

  storage_type          = "GRS"

  loganalytics_workspace_id = module.logs.id

  minimum_instance_count = 2
  maximum_instance_count = 5

}


module "service_alpha" {
  
  source                      = "github.com/markti/tf_azure_microservices/http/base_v2"

  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  name                        = "${local.app_name}-${local.env_name}-alpha-${local.location_suffix}"

  app_name                    = local.app_name
  env_name                    = local.env_name
  service_name                = "Alpha"

  host_settings               = module.microservice_hub.host_settings

  azure_function_version      = "~2"
  worker_runtime              = "dotnet"
  app_settings                = { }
  deployment_package_filename = "./drop/DemoCode.zip"

  loganalytics_workspace_id   = module.logs.id

}

module "service_beta" {
  
  source                      = "github.com/markti/tf_azure_microservices/eventgrid/base_v3"

  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  name                        = "${local.app_name}-${local.env_name}-beta-${local.location_suffix}"

  app_name                    = local.app_name
  env_name                    = local.env_name
  service_name                = "Beta"

  host_settings               = module.microservice_hub.host_settings

  azure_function_version      = "~2"
  worker_runtime              = "dotnet"
  app_settings                = { }
  deployment_package_filename = "./drop/DemoCode.zip"

  loganalytics_workspace_id   = module.logs.id

}