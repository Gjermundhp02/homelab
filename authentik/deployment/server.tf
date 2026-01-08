resource "random_password" "authentik_secret_key" {
  length  = 50
  special = true
}

resource "azurerm_key_vault_secret" "authentik_secret_key" {
  name         = "authentik-secret-key"
  value        = random_password.authentik_secret_key.result
  key_vault_id = azurerm_key_vault.deployment.id
}

resource "azurerm_container_app" "server" {
  name                         = "server"
  container_app_environment_id = data.azurerm_container_app_environment.website_env.id
  resource_group_name          = data.azurerm_resource_group.homelab-rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.authentik_identity.id]
  }

  secret {
    name                = "postgres-password"
    key_vault_secret_id = azurerm_key_vault_secret.postgres_password.id
    identity            = azurerm_user_assigned_identity.authentik_identity.id
  }

  secret {
    name                = "authentik-secret-key"
    key_vault_secret_id = azurerm_key_vault_secret.authentik_secret_key.id
    identity            = azurerm_user_assigned_identity.authentik_identity.id
  }

  ingress {
    external_enabled = true
    target_port      = 9000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "server"
      image  = "ghcr.io/goauthentik/server:2025.10.3"
      cpu    = 1
      memory = "2Gi"
      
      args = ["server"]
      
      env {
        name  = "AUTHENTIK_POSTGRESQL__HOST"
        value = "postgres"
      }
      env {
        name  = "AUTHENTIK_POSTGRESQL__PORT"
        value = "5432"
      }
      env {
        name  = "AUTHENTIK_POSTGRESQL__NAME"
        value = local.postgres_db
      }
      env {
        name  = "AUTHENTIK_POSTGRESQL__USER"
        value = local.postgres_user
      }
      env {
        name        = "AUTHENTIK_POSTGRESQL__PASSWORD"
        secret_name = "postgres-password"
      }
      env {
        name        = "POSTGRES_PASSWORD"
        secret_name = "postgres-password"
      }
      env {
        name        = "AUTHENTIK_SECRET_KEY"
        secret_name = "authentik-secret-key"
      }
      
      volume_mounts {
        name = "media"
        path = "/media"
      }
      volume_mounts {
        name = "custom-templates"
        path = "/templates"
      }
    }
    min_replicas = 1
    
    volume {
      name = "media"
    }
    volume {
      name = "custom-templates"
    }
  }
  depends_on = [ azurerm_container_app.postgres ]
}