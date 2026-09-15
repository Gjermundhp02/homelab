{config, ...}: {
  imports = [
    (import ../monitoring-agent.nix {lokiUrl = "http://127.0.0.1:3100/loki/api/v1/push";})
  ];

  sops.secrets.grafana_admin_password = {
    owner = "grafana";
    restartUnits = ["grafana.service"];
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_port = 3100;
        http_listen_address = "0.0.0.0";
      };
      common = {
        instance_addr = "127.0.0.1";
        path_prefix = "/var/lib/loki";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
      };
      schema_config.configs = [
        {
          from = "2025-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      limits_config.retention_period = "744h";
    };
  };

  services.prometheus = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9090;
    retentionTime = "30d";
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [
              "localhost:9100"
              "192.168.101.2:9100" # compute
              "192.168.101.20:9100" # game-server (compute microvm)
              "192.168.100.10:9100" # immich (nas microvm)
            ];
          }
        ];
      }
      {
        job_name = "crowdsec";
        static_configs = [
          {
            targets = [
              "localhost:6060"
              "192.168.101.2:6060" # compute
            ];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security.admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
    };
    provision = {
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            uid = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            uid = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "security";
            type = "file";
            options.path = ./grafana-dashboards;
          }
        ];
      };
    };
  };

  networking.firewall.interfaces.eno1.allowedTCPPorts = [3100];
  networking.firewall.interfaces.microbr0.allowedTCPPorts = [3100];
}
