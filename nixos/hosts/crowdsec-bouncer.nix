{ config, ... }: {
  sops.secrets."crowdsec/bouncer_key" = {
    restartUnits = [ "crowdsec-firewall-bouncer.service" ];
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
    registerBouncer.enable = false;
    secrets.apiKeyPath = config.sops.secrets."crowdsec/bouncer_key".path;
  };
}
