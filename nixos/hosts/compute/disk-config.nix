{
  disko.devices = {
    disk = {
      # 1. Separate Drive: EFI Boot (/boot) and Encrypted Root (/)
      separate_drive = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0K394356A";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted-root";
                passwordFile = "/tmp/luks_password.txt";
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };

      # 2. SSD 1 for RAID 1
      ssd1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-SAMSUNG_MZ7LN128HAHQ-000L1_S3R4NX0M208750";
        content = {
          type = "gpt";
          partitions = {
            raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };

      # 3. SSD 2 for RAID 1
      ssd2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-SanDisk_SD9SB8W128G1001_181712801857";
        content = {
          type = "gpt";
          partitions = {
            raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };
    };

    # 4. RAID 1 -> LUKS -> LVM Physical Volume
    mdadm = {
      raid1 = {
        type = "mdadm";
        level = 1;
        content = {
          type = "luks";
          name = "crypted-raid";
          passwordFile = "/tmp/luks_password.txt";
          settings.allowDiscards = true;
          content = {
            type = "lvm_pv";
            vg = "vg-data";
          };
        };
      };
    };

    # 5. Top-Level LVM Volume Group Definition
    lvm_vg = {
      vg-data = {
        type = "lvm_vg";
        lvs = {
          data = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/mnt/data";
            };
          };
        };
      };
    };
  };
}