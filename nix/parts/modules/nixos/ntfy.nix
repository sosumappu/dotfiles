let
  module = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.ntfy;
  in {
    options.my.modules.ntfy = with lib; {
      port = mkOption {
        type = types.port;
        default = 2586;
      };
      baseUrl = mkOption {
        type = types.str;
        example = "https://ntfy.berry.local";
      };
      secretsFile = mkOption {
        type = types.str;
        default = "/etc/secrets/ntfy.conf";
      };
    };

    config = {
      services.ntfy-sh = {
        enable = true;
        settings = {
          listen-http = ":${toString cfg.port}";
          base-url = cfg.baseUrl;
          auth-default-access = "deny-all";
          cache-file = "/var/lib/ntfy-sh/cache.db";
          cache-duration = "24h";
          auth-file = "/var/lib/ntfy-sh/user.db";
          keepalive-interval = "45s";
        };
      };

      systemd.services.ntfy-sh.serviceConfig.EnvironmentFile = cfg.secretsFile;

      environment.systemPackages = [
        (pkgs.writeShellScriptBin "notify-homelab" ''
          set -euo pipefail
          TOPIC="''${1:?Usage: notify-homelab <topic> <title> <message>}"
          TITLE="''${2:?missing title}"
          MESSAGE="''${3:?missing message}"
          shift 3
          ${pkgs.curl}/bin/curl -s \
            --url "${cfg.baseUrl}/$TOPIC" \
            --header "Title: $TITLE" \
            ''${NTFY_TOKEN:+--header "Authorization: Bearer $NTFY_TOKEN"} \
            --data "$MESSAGE" \
            "$@"
        '')
      ];
    };
  };
in {
  flake.modules.nixos.ntfy = module;
}
