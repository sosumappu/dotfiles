let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }:
      with config.my; let
        cfg = config.my.modules.syncthing;
        homeDir = config.my.user.home;
        inherit (config.home-manager.users."${username}") xdg;

        knownPeers = {
          berry = {
            id = "USBTMQ7-EKZJMQ5-SA2WGVQ-H2XZSOD-5UPQXVE-YRN5MQD-5PNSV2T-S7RKHQH";
            addresses = ["dynamic"];
          };
          erdnase = {
            id = "6WNQZIO-34QCJDF-BT4ENXR-LMKFSQX-4KLQ5N5-GDI2SIK-FKES7HT-IEPZUAK";
            addresses = ["dynamic"];
          };
        };
      in {
        options = with lib; {
          my.modules.syncthing = {
            peers = mkOption {
              type = types.listOf (types.enum (builtins.attrNames knownPeers));
              default = [];
              description = "List of peer names this host should connect to. Must be keys in knownPeers.";
              example = ["server" "desktop"];
            };

            folders = mkOption {
              type = types.attrsOf (types.submodule {
                options = {
                  label = mkOption {
                    type = types.str;
                    default = "";
                  };
                  path = mkOption {
                    type = types.str;
                    description = "Absolute path to the synced folder on this host";
                  };
                  devices = mkOption {
                    type = types.listOf types.str;
                    default = [];
                    description = "Peer names (keys in cfg.peers) to share this folder with";
                  };
                  type = mkOption {
                    type = types.enum ["sendreceive" "sendonly" "receiveonly" "receiveencrypted"];
                    default = "sendreceive";
                  };
                };
              });
              default = {};
            };
          };
        };
        config = with lib; {
          my.user.packages = with pkgs; [syncthing];
          home-manager.users."${username}".services.syncthing = {
            enable = true;
            overrideDevices = true;
            overrideFolders = true;

            settings = {
              devices = genAttrs cfg.peers (name: {
                inherit (knownPeers.${name}) id addresses;
              });
              folders =
                mapAttrs (_: folder: {
                  inherit (folder) label path type;
                  inherit (folder) devices;
                })
                cfg.folders;
            };
          };
        };
      };
  };
in {
  flake.modules = {
    generic.syncthing = module.generic;
  };
}
