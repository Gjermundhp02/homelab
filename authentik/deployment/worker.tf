resource "azurerm_container_app" "worker" {
  name                         = "worker"
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

  template {
    container {
      name   = "worker"
      image  = "ghcr.io/goauthentik/server:2025.10.3"
      cpu    = 1
      memory = "2Gi"

      command = [ "ak", "worker" ]
      args     = []

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
      env {
        name  = "PUID"
        value = "0"
      }
      env {
        name  = "PGID"
        value = "0"
      }
      
      volume_mounts {
        name = "media"
        path = "/media"
      }
      volume_mounts {
        name = "certs"
        path = "/certs"
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
      name = "certs"
    }
    volume {
      name = "custom-templates"
    }
  }
  depends_on = [ azurerm_container_app.postgres ]
}
