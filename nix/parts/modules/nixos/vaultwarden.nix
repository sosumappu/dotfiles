let
  module = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.vaultwarden;
  in {
    options.my.modules.vaultwarden = with lib; {
      port = mkOption {
        type = types.port;
        default = 8222;
      };
      domain = mkOption {
        type = types.str;
        example = "vault.berry.local";
      };
      secretsFile = mkOption {
        type = types.str;
        default = "/etc/secrets/vaultwarden.conf";
      };
    };

    config = {
      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        environmentFile = cfg.secretsFile;
        config = {
          ROCKET_PORT = cfg.port;
          ROCKET_ADDRESS = "127.0.0.1";
          DOMAIN = "https://${cfg.domain}";
          SIGNUPS_ALLOWED = false;
          WEBSOCKET_ENABLED = true;
          LOG_LEVEL = "warn";
          LOGIN_RATELIMIT_MAX_BURST = 10;
          LOGIN_RATELIMIT_SECONDS = 60;
        };
      };

      systemd.services.vaultwarden-wal-flush = {
        description = "Flush Vaultwarden SQLite WAL before backup";
        serviceConfig = {
          Type = "oneshot";
          User = "vaultwarden";
          ExecStart = pkgs.writeShellScript "vaultwarden-wal-flush" ''
            set -euo pipefail
            DB="/var/lib/vaultwarden/db.sqlite3"
            [ -f "$DB" ] && ${pkgs.sqlite}/bin/sqlite3 "$DB" "PRAGMA wal_checkpoint(TRUNCATE);"
          '';
        };
      };
    };
  };
in {
  flake.modules.nixos.vaultwarden = module;
}
