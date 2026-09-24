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

      rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "syslog_identifier"
      }

      rule {
        source_labels = ["__journal__uid"]
        target_label  = "uid"
      }

      # sshd-session sets its own cmdline to "sshd-session: <user>@<subsystem>"
      # (confirmed via `journalctl --output=export`, the raw field is
      # literally quote-wrapped: _CMDLINE="sshd-session: gjermund@internal-sftp").
      # This pulls the username out for any user, not just one hardcoded account.
      rule {
        source_labels = ["__journal__cmdline"]
        regex         = "\"sshd-session: (.+)@internal-sftp\""
        target_label  = "user"
        replacement   = "$1"
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
