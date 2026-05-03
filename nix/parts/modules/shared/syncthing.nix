let
  module = let
    # Shared options definition — used by both platform modules
    mkOptions = lib:
      with lib; {
        my.modules.syncthing = {
          # This host's own device ID — used by peers to identify it.
          # Get it from: syncthing --device-id
          deviceId = mkOption {
            type = types.str;
            default = "";
            description = "This host's Syncthing device ID";
            example = "AAAAAAA-BBBBBBB-CCCCCCC-DDDDDDD-EEEEEEE-FFFFFFF-GGGGGGG-HHHHHHH";
          };

          # All known peers, keyed by a human name.
          # Each host declares the full peer map — including itself if desired,
          # though Syncthing ignores self-entries.
          #
          # Example in a host config:
          #   my.modules.syncthing.peers = {
          #     berry   = { id = "AAAA..."; };
          #     erdnase = { id = "BBBB..."; addresses = ["tcp://erdnase.local:22000"]; };
          #     phone   = { id = "CCCC..."; };
          #   };
          peers = mkOption {
            type = types.attrsOf (types.submodule {
              options = {
                id = mkOption {
                  type = types.str;
                  description = "Syncthing device ID of this peer";
                };
                addresses = mkOption {
                  type = types.listOf types.str;
                  default = ["dynamic"];
                  description = "Addresses to contact this peer at. 'dynamic' uses discovery.";
                  example = ["tcp://berry.local:22000"];
                };
                autoAcceptFolders = mkOption {
                  type = types.bool;
                  default = false;
                };
              };
            });
            default = {};
          };

          # Folders to sync, keyed by Syncthing folder ID.
          # Devices listed here must be keys in cfg.peers.
          #
          # Example:
          #   my.modules.syncthing.folders = {
          #     "dev-folder" = {
          #       label   = "Dev";
          #       path    = "/home/localhost/dev";
          #       devices = ["berry" "erdnase"];
          #     };
          #   };
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

    nixosModule = {
      pkgs,
      lib,
      config,
      ...
    }:
      with config.my; let
        cfg = config.my.modules.syncthing;
        homeDir = config.my.user.home;
        inherit (config.home-manager.users."${username}") xdg;
      in {
        options = mkOptions lib;

        config = with lib; {
          my.user.packages = [pkgs.syncthing];

          services.syncthing = {
            enable = true;
            user = config.my.username;
            dataDir = homeDir;
            configDir = "${xdg.configHome}/syncthing";
            overrideDevices = true;
            overrideFolders = true;

            settings = {
              devices =
                mapAttrs (_: peer: {
                  inherit (peer) id addresses autoAcceptFolders;
                })
                cfg.peers;

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

    darwinModule = {
      pkgs,
      lib,
      config,
      ...
    }:
      with config.my; let
        cfg = config.my.modules.syncthing;
        inherit (config.home-manager.users."${username}") xdg;
        homeDir = config.my.user.home;
      in {
        options = mkOptions lib;

        config = with lib; {
          my.user.packages = with pkgs; [syncthing];

          # nix-darwin has no services.syncthing, so we run it as a launchd user agent
          launchd.user.agents.syncthing = {
            path = [config.environment.systemPath];
            serviceConfig = {
              ProgramArguments = [
                "${pkgs.syncthing}/bin/syncthing"
                "--no-browser"
                "--no-restart"
                "--logflags=0"
                "--config=${xdg.configHome}/syncthing"
                "--data=${xdg.dataHome}/syncthing"
              ];
              KeepAlive = true;
              RunAtLoad = true;
              ProcessType = "Background";
              StandardOutPath = "${homeDir}/Library/Logs/syncthing.log";
              StandardErrorPath = "${homeDir}/Library/Logs/syncthing.log";
            };
          };

          # On Darwin, folder/peer config is written to the Syncthing XML config
          # via a home-manager activation script since there's no NixOS service
          # module to handle overrideDevices/overrideFolders for us.
          # Syncthing will merge this on startup when -no-restart is not used,
          # so we write it once and let Syncthing own it after that.
          system.activationScripts.postActivation.text = with builtins; let
            configDir = "${xdg.configHome}/syncthing";
          in ''
            echo ":: -> syncthing: ensuring config dir exists..."
            mkdir -p ${configDir}
          '';
        };
      };
  in {
    darwin = darwinModule;
    nixos = nixosModule;
  };
in {
  flake.modules = {
    darwin.syncthing = module.darwin;
    nixos.syncthing = module.nixos;
  };
}
