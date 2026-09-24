# Deploy commands
## New
``
## Rebuild
- `nixos-rebuild switch --flake ./#nas --sudo --target-host gjermund@nas`
- `NIX_SSHOPTS="-J gjermund@nas" nixos-rebuild switch   --flake /home/gjermund/Documents/homelab/nixos#compute   --target-host gjermund@192.168.101.2  --sudo`