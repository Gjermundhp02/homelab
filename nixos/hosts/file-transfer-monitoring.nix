{pkgs, ...}: let
  usbAuditWatch = pkgs.writeShellScript "usb-audit-watch" ''
    for d in /mnt/usb/*/; do
      [ -d "$d" ] || continue
      ${pkgs.util-linux}/bin/mountpoint -q "$d" || continue
      ${pkgs.audit}/bin/auditctl -w "''${d%/}" -p rwxa -k usb_files 2>/dev/null || true
    done
  '';
in {
  # Physical USB device attach/detach, tagged so it's easy to grep out of
  # systemd-udevd's journal stream.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="${pkgs.util-linux}/bin/logger -t usb-monitor USB device inserted: vendor=$env{ID_VENDOR} model=$env{ID_MODEL} serial=$env{ID_SERIAL_SHORT}"
    ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="${pkgs.util-linux}/bin/logger -t usb-monitor USB device removed: vendor=$env{ID_VENDOR} model=$env{ID_MODEL} serial=$env{ID_SERIAL_SHORT}"
  '';

  # USB drives are mounted manually as /mnt/usb/<label>.
  systemd.tmpfiles.rules = ["d /mnt/usb 0755 root root -"];

  security.auditd.enable = true;
  # auditd declares the syslog dispatcher plugin but ships it inactive by
  # default; without this, audit events never reach the journal for Alloy/Loki.
  security.auditd.plugins.syslog.active = true;

  # auditctl watches are tied to a mount's inode, so a static rule on /mnt/usb
  # doesn't follow new drives mounted under it. Re-scan on every change to
  # /mnt/usb (a mount/unmount) and register a watch for whatever is mounted.
  systemd.services.usb-audit-watch = {
    description = "Register auditd watches for mounted USB drives";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${usbAuditWatch}";
    };
  };

  systemd.paths.usb-audit-watch = {
    wantedBy = ["multi-user.target"];
    pathConfig.PathChanged = "/mnt/usb";
  };

  # Modern `scp` speaks SFTP under the hood, so logging file transfers means
  # switching to the built-in sftp-server and turning its logging up.
  services.openssh.sftpServerExecutable = "internal-sftp";
  services.openssh.sftpFlags = ["-l INFO"];
}
