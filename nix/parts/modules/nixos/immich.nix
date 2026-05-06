let
  module = {
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.immich;
  in {
    options.my.modules.immich = with lib; {
      port = mkOption {
        type = types.port;
        default = 2283;
      };
      mediaLocation = mkOption {
        type = types.str;
      };
      secretsFile = mkOption {
        type = types.str;
        default = "/etc/secrets/immich.conf";
      };
      settings = mkOption {
        type = types.attrsOf types.anything;
        default = {};
      };
    };

    config = {
      services.immich = {
        enable = true;
        host = "0.0.0.0";
        machine-learning.enable = false;
        inherit (cfg) port mediaLocation settings;
        inherit (cfg) secretsFile;
      };
    };
  };
in {
  flake.modules.nixos.immich = module;
}
