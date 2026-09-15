{lokiUrl}: {
  config,
  lib,
  ...
}: {
  services.alloy.enable = true;

  environment.etc."alloy/config.alloy".text = ''
    discovery.relabel "journal" {
      targets = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal__hostname"]
        target_label  = "host"
      }
    }

    loki.source.journal "journal" {
      path          = "/var/log/journal"
      relabel_rules = discovery.relabel.journal.rules
      forward_to    = [loki.write.nas.receiver]
    }

    loki.write "nas" {
      endpoint {
        url = "${lokiUrl}"
      }
    }
  '';

  services.prometheus.exporters.node.enable = true;

  services.crowdsec.settings.general.prometheus.listen_addr = lib.mkIf config.services.crowdsec.enable "0.0.0.0";
}
