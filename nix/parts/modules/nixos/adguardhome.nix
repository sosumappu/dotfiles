# AdGuard Home module
#
# Serves as both an ad-blocking DNS resolver and the source of local DNS
# entries for your *.berry.local (or any domain) homelab services.
#
# AdGuard rewrites take priority over upstream DNS, so you can have:
#   immich.berry.local   → 192.168.1.10  (your server's LAN IP)
#   vault.berry.local    → 192.168.1.10
#   ntfy.berry.local     → 192.168.1.10
# ...without touching /etc/hosts on every device.
#
# Point your router's DHCP DNS option at this host's IP and every device
# on your LAN gets the rewrites automatically.
#
# The service reads its runtime config (blocklists, user rules, sessions)
# from cfg.dataDir. The static config options below are written to
# AdGuardHome.yaml on each activation. AdGuard merges them on startup.
#
# Secrets (if you enable the web UI with auth):
#   /etc/secrets/adguardhome.conf must export:
#     ADGUARD_PASSWORD_HASH=<bcrypt hash>
#   Generate with: htpasswd -bnBC 10 "" yourpassword | tr -d ':\n'
let
  module = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.adguardhome;
  in {
    options = with lib; {
      my.modules.adguardhome = {
        port = mkOption {
          type = types.port;
          default = 53;
          description = "DNS listening port";
        };

        webPort = mkOption {
          type = types.port;
          default = 3000;
          description = "AdGuard Home web UI port";
        };

        # LAN IP of this host — used as the A record target for all rewrites
        lanIp = mkOption {
          type = types.str;
          description = "LAN IP of this host, used as the target for local DNS rewrites";
          example = "192.168.1.10";
        };

        # Domain whose subdomains are rewritten to lanIp.
        # Set this to match my.modules.caddy.domain.
        # Every key in my.modules.caddy.services becomes a rewrite automatically
        # if autoRegisterCaddyServices = true.
        localDomain = mkOption {
          type = types.str;
          description = "Base domain for local rewrites, should match caddy.domain";
          example = "berry.local";
        };

        # When true, reads config.my.modules.caddy.services and creates a
        # DNS rewrite for each service automatically.
        # Requires the caddy module to be imported on the same host.
        autoRegisterCaddyServices = mkOption {
          type = types.bool;
          default = true;
          description = "Auto-create DNS rewrites for all my.modules.caddy.services entries";
        };

        # Extra rewrites beyond the auto-generated ones.
        # Useful for devices, printers, NAS, etc.
        extraRewrites = mkOption {
          type = types.listOf (types.submodule {
            options = {
              domain = mkOption {type = types.str;};
              answer = mkOption {type = types.str;};
            };
          });
          default = [];
          example = [
            {
              domain = "router.home";
              answer = "192.168.1.1";
            }
            {
              domain = "nas.home";
              answer = "192.168.1.20";
            }
          ];
        };

        # Upstream DNS resolvers used for everything outside localDomain.
        # Defaults to Cloudflare + quad9 over HTTPS (DNS-over-HTTPS).
        upstreamDns = mkOption {
          type = types.listOf types.str;
          default = [
            "https://1.1.1.1/dns-query"
            "https://9.9.9.9/dns-query"
          ];
        };

        bootstrapDns = mkOption {
          type = types.listOf types.str;
          default = ["1.1.1.1:53" "9.9.9.9:53"];
          description = "Plain DNS used to resolve the DoH upstream hostnames on startup";
        };

        # Blocklists — these are the most useful ones for a homelab.
        # Add/remove per taste; AdGuard fetches and caches them.
        blocklists = mkOption {
          type = types.listOf (types.submodule {
            options = {
              name = mkOption {type = types.str;};
              url = mkOption {type = types.str;};
              enabled = mkOption {
                type = types.bool;
                default = true;
              };
            };
          });
          default = [
            {
              name = "AdGuard DNS filter";
              url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
              enabled = true;
            }
            {
              name = "OISD Big";
              url = "https://big.oisd.nl";
              enabled = true;
            }
            {
              name = "Peter Lowe's Blocklist";
              url = "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=1&mimetype=plaintext";
              enabled = true;
            }
          ];
        };

        secretsFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "agenix-managed env file (optional, for web UI auth token)";
          example = "/etc/secrets/adguardhome.conf";
        };

        dataDir = mkOption {
          type = types.str;
          default = "/var/lib/AdGuardHome";
        };
      };
    };

    config = with lib; let
      # Build the full rewrite list
      caddyRewrites =
        lib.optionals
        (cfg.autoRegisterCaddyServices && config.my.modules ? caddy)
        (lib.mapAttrsToList (name: _: {
            domain = "${name}.${cfg.localDomain}";
            answer = cfg.lanIp;
          })
          config.my.modules.caddy.services);

      allRewrites = caddyRewrites ++ cfg.extraRewrites;

      # Also add a wildcard rewrite as a catch-all for the local domain.
      # This means even services not in caddy.services resolve correctly
      # (Caddy will 404, but DNS resolves — useful during setup).
      wildcardRewrite = {
        domain = "*.${cfg.localDomain}";
        answer = cfg.lanIp;
      };

      adguardConfig = {
        bind_host = "0.0.0.0";
        bind_port = cfg.webPort;

        dns = {
          bind_hosts = ["0.0.0.0"];
          inherit (cfg) port;
          upstream_dns = cfg.upstreamDns;
          bootstrap_dns = cfg.bootstrapDns;
          rewrites = [wildcardRewrite] ++ allRewrites;

          # Sensible security defaults
          filtering_enabled = true;
          filters_update_interval = 24;
          parental_control_enabled = false;
          safebrowsing_enabled = false; # can slow things down
          safe_search.enabled = false;

          # Cache settings
          cache_size = 4194304; # 4MB
          cache_ttl_min = 0;
          cache_ttl_max = 0;
          cache_optimistic = true;

          blocked_response_ttl = 10;
          ratelimit = 20;
          refuse_any = true;
          upstream_timeout = "10s";
        };

        filters =
          map (bl: {
            inherit (bl) name url enabled;
            id = builtins.hashString "sha256" bl.url; # stable ID from URL
          })
          cfg.blocklists;

        log = {
          file = ""; # stderr → journald
          max_size = 100;
          max_age = 7;
          compress = false;
          verbose = false;
        };

        statistics.enabled = true;
        statistics.interval = "168h"; # 7 days

        querylog.enabled = true;
        querylog.size_memory = 1000;
        querylog.interval = "24h";
        querylog.anonymize_client_ip = false;
      };

      configFile = pkgs.writeText "AdGuardHome.yaml" (
        builtins.toJSON adguardConfig
      );
    in {
      services.adguardhome = {
        enable = true;
        mutableSettings = true; # allow the web UI to persist changes
        settings = builtins.fromJSON (builtins.readFile configFile);
      };

      systemd.services.AdGuardHome = lib.mkIf (cfg.secretsFile != null) {
        serviceConfig.EnvironmentFile = cfg.secretsFile;
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 adguardhome adguardhome -"
      ];

      # Allow DNS through the firewall
      networking.firewall = {
        allowedTCPPorts = [cfg.port cfg.webPort];
        allowedUDPPorts = [cfg.port];
      };
    };
  };
in {
  flake.modules.nixos.adguardhome = module;
}
