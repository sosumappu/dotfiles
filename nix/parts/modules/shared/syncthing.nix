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
            id = "O3VOH5C-DVH5PRR-Y773HXN-23QGRAW-JHNDUWJ-CDTLXOW-M2DIHBD-LT5KAQC";
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
          services.syncthing = {
            enable = true;
            user = config.my.username;
            dataDir = homeDir;
            configDir = "${xdg.configHome}/syncthing";
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
