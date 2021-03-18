provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "prd" {
  name     = "prd-microservices-group"
  location = "West Europe"
}

resource "azurerm_mysql_server" "prd" {
  name = "prd-webapp-mysql-server"
  location = azurerm_resource_group.prd.location
  administrator_login = "edoardo"
  administrator_login_password = "P@ssw0rd"
  auto_grow_enabled = true
  sku_name = "B_Gen5_2"
  backup_retention_days = 7
  resource_group_name = azurerm_resource_group.prd.name
  public_network_access_enabled = true
  storage_mb = 5120
  ssl_enforcement_enabled = true
  infrastructure_encryption_enabled = false
  version = "5.7"

}

resource "azurerm_mysql_firewall_rule" "prd" {
    name = "prd-mysql-firewall-rule"
    server_name = azurerm_mysql_server.prd.name
    start_ip_address = "93.66.54.100"
    end_ip_address = "93.66.54.100"
  resource_group_name = azurerm_resource_group.prd.name
  
}

resource "azurerm_mysql_database" "prd" {
  name = "library"
  resource_group_name = azurerm_resource_group.prd.name
  server_name =  azurerm_mysql_server.prd.name
  collation = "utf8_unicode_ci"
  charset = "utf8"

}

resource "azurerm_app_service_plan" "prd" {
  name="library-service-plan"
  resource_group_name = azurerm_resource_group.prd.name
  location=  azurerm_resource_group.prd.location

  sku {
      tier = "Basic"
      size = "B1"
  }
}

resource "azurerm_spring_cloud_service" "prd" {
  name                = "prd-library"
  resource_group_name = azurerm_resource_group.prd.name
  location            = azurerm_resource_group.prd.location
  sku_name            = "S0"

  config_server_git_setting {
    uri          = "https://github.com/Azure-Samples/piggymetrics"
    label        = "config"
    search_paths = ["dir1", "dir2"]
  }

  trace {
    instrumentation_key = azurerm_application_insights.prd.instrumentation_key
  }

  tags = {
    Env = "staging"
  }
}
