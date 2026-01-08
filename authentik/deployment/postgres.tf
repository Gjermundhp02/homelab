locals {
  postgres_db     = "authentik"
  postgres_user   = "authentik"
}

resource "random_password" "postgrespass" {
  length           = 20
  special          = true
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgrespass"
  value        = random_password.postgrespass.result
  key_vault_id = azurerm_key_vault.deployment.id
}

resource "azurerm_container_app" "postgres" {
  name                         = "postgres"
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

  ingress {
    external_enabled = false  # Internal only
    target_port      = 5432
    transport        = "tcp"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "postgres"
      image  = "docker.io/library/postgres:16-alpine"
      cpu    = 0.5
      memory = "1Gi"
      
      env {
        name  = "POSTGRES_DB"
        value = local.postgres_db
      }
      env {
        name  = "POSTGRES_USER"
        value = local.postgres_user
      }
      env {
        name        = "POSTGRES_PASSWORD"
        secret_name = "postgres-password"
      }
      
      startup_probe {
        transport = "TCP"
        port      = 5432
        timeout   = 5
      }
      
      readiness_probe {
        transport = "TCP"
        port      = 5432
        timeout   = 5
      }
      
      liveness_probe {
        transport = "TCP"
        port      = 5432
        timeout   = 5
      }
      
      volume_mounts {
        name = "postgres-data"
        path = "/var/lib/postgresql/data"
      }
    }
    min_replicas = 1
    volume {
      name = "postgres-data"
    }
  }
}