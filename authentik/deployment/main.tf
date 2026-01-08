# Managed Identity for Container Apps to access Key Vault
resource "azurerm_user_assigned_identity" "authentik_identity" {
  location            = data.azurerm_storage_account.authentik.location
  name                = "authentik-identity"
  resource_group_name = data.azurerm_resource_group.homelab-rg.name
}

resource "azurerm_key_vault" "deployment" {
  name                        = "authentikdeploymentkv"
  location                    = data.azurerm_storage_account.authentik.location
  resource_group_name         = data.azurerm_resource_group.homelab-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
      "Purge"
    ]

    storage_permissions = [
      "Get",
    ]
  }

  # Access policy for the managed identity used by Container Apps
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.authentik_identity.principal_id

    secret_permissions = [
      "Get",
    ]
  }
}
