/**
  * # App module
  *
  * This module will create the Azure Web App to run the API application including all
  * requirements like App Service Plan and VNet integration.
  *
 */

resource "azurerm_app_service_plan" "this" {
  name                         = var.sp_name
  location                     = var.azure_region
  resource_group_name          = var.resource_group_name
  kind                         = "Linux"
  reserved                     = true # this is required for app service of kind Linux
  per_site_scaling             = var.per_site_scaling
  maximum_elastic_worker_count = var.maximum_elastic_worker_count

  sku {
    tier     = var.tier
    size     = var.size
    capacity = var.number_of_workers
  }

  tags = merge({
    "name"        = var.sp_name,
    "Environment" = var.stage_name,
    "Location" = var.azure_region },
  var.default_tags)

}

resource "azurerm_app_service" "this" {
  app_service_plan_id = azurerm_app_service_plan.this.id
  location            = var.azure_region
  name                = var.app_name
  resource_group_name = var.resource_group_name

  https_only = true

  site_config {
    always_on         = var.allways_on
    health_check_path = var.health_check_path
    ftps_state        = "Disabled"
    http2_enabled     = var.http2_enabled
    linux_fx_version  = var.linux_fx_version
    app_command_line  = var.app_command_line
    min_tls_version   = "1.2"
    number_of_workers = var.number_of_workers


    # java_version = var.java_version
    # java_container = var.java_container
    # java_container_version = var.java_container_version

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        name                      = lookup(ip_restriction.value, "name", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
        action                    = lookup(ip_restriction.value, "action", null)
        priority                  = lookup(ip_restriction.value, "priority", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "vnet_subnet_id", null)
      }

    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = var.app_settings

  logs {
    detailed_error_messages_enabled = var.detailed_error_messages
    failed_request_tracing_enabled  = var.failed_request_tracing
    application_logs {
      file_system_level = var.application_logs_level
    }
    http_logs {
      file_system {
        retention_in_days = var.http_logs_retention_in_days
        retention_in_mb   = var.http_logs_retention_in_mb
      }
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings["BRANCH_NAME"],
      app_settings["BUILD_ID"],
      app_settings["BUILD_NO"],
      app_settings["BUILD_SOURCE_VERSION"],
      app_settings["RELEASE"],
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"]
    ]
  }

  tags = merge({
    "name"        = var.app_name,
    "Environment" = var.stage_name,
    "Location" = var.azure_region },
  var.default_tags)
}

resource "azurerm_app_service_virtual_network_swift_connection" "this" {
  count          = var.assign_subnet ? 1 : 0
  app_service_id = azurerm_app_service.this.id
  subnet_id      = var.subnet_id
}

resource "azurerm_app_service_slot" "this" {
  count               = var.deploy_slot ? 1 : 0
  name                = "staging"
  app_service_name    = var.app_name
  resource_group_name = var.resource_group_name
  location            = var.azure_region

  app_service_plan_id = azurerm_app_service_plan.this.id


  https_only = true

  site_config {
    always_on         = var.allways_on
    health_check_path = var.health_check_path
    ftps_state        = "Disabled"
    http2_enabled     = var.http2_enabled
    linux_fx_version  = var.linux_fx_version
    app_command_line  = var.app_command_line
    min_tls_version   = "1.2"


    # java_version = var.java_version
    # java_container = var.java_container
    # java_container_version = var.java_container_version

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        name                      = lookup(ip_restriction.value, "name", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
        action                    = lookup(ip_restriction.value, "action", null)
        priority                  = lookup(ip_restriction.value, "priority", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "vnet_subnet_id", null)
      }

    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = var.app_settings

  logs {
    detailed_error_messages_enabled = var.detailed_error_messages
    failed_request_tracing_enabled  = var.failed_request_tracing
    application_logs {
      file_system_level = var.application_logs_level
    }
    http_logs {
      file_system {
        retention_in_days = var.http_logs_retention_in_days
        retention_in_mb   = var.http_logs_retention_in_mb
      }
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings["BRANCH_NAME"],
      app_settings["BUILD_ID"],
      app_settings["BUILD_NO"],
      app_settings["BUILD_SOURCE_VERSION"],
      app_settings["RELEASE"],
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["DEPLOYMENT_SLOT"]
    ]
  }

  tags = merge({
    "name"        = var.app_name,
    "Environment" = var.stage_name,
    "Location" = var.azure_region },
  var.default_tags)
}

resource "azurerm_app_service_slot_virtual_network_swift_connection" "this" {
  count          = var.deploy_slot ? 1 : 0
  slot_name      = azurerm_app_service_slot.this[0].name
  app_service_id = azurerm_app_service.this.id
  subnet_id      = var.subnet_id
}
