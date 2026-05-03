# Caddy reverse proxy module
#
# Generates a Caddyfile that routes *.${cfg.domain} to local services.
# Each service registers itself via my.modules.caddy.services.<name>.
#
# TLS options:
#   - "internal"  : Caddy acts as its own local CA, issues certs automatically.
#                   Requires trusting Caddy's root CA on each client once.
#                   Best for a closed homelab with no public DNS.
#   - "acme-dns"  : Real Let's Encrypt wildcard cert via DNS challenge.
#                   Requires a supported DNS provider (Cloudflare, etc.) and
#                   an API token in secretsFile.
#                   Best if you have a real domain pointing at your LAN.
#
# Usage on a host:
#
#   imports = [ inputs.self.modules.nixos.caddy ];
#
#   my.modules.caddy = {
#     domain = "berry.local";
#     tls.mode = "internal";      # or "acme-dns"
#   };
#
# Services declare themselves — no need to touch this module when adding one:
#
#   my.modules.caddy.services.immich = {
#     upstream = "http://localhost:${toString config.my.modules.immich.port}";
#   };
#
#   # Results in: immich.berry.local → http://localhost:2283
let
  module = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.caddy;
  in {
    options = with lib; {
      my.modules.caddy = {
        domain = mkOption {
          type = types.str;
          description = "Base domain for all services, e.g. 'berry.local' yields immich.berry.local";
          example = "berry.local";
        };

        tls = {
          mode = mkOption {
            type = types.enum ["internal" "acme-dns"];
            default = "internal";
            description = ''
              "internal" — Caddy's built-in CA, no external dependencies. Trust the
                           root cert once per client (Caddy prints its CA cert path on startup).
              "acme-dns"  — Real LE wildcard cert via DNS challenge. Needs secretsFile
                           with your DNS provider API token.
            '';
          };

          # Only used when mode = "acme-dns"
          # agenix-managed file at /etc/secrets/caddy.conf
          # Must export (shell-style):
          #   CLOUDFLARE_AUTH_TOKEN=<token>   (or your provider's var)
          secretsFile = mkOption {
            type = types.str;
            default = "/etc/secrets/caddy.conf";
          };

          # DNS provider module to build Caddy with when mode = "acme-dns".
          # See: https://github.com/caddy-dns — pick the one matching your registrar.
          dnsProvider = mkOption {
            type = types.str;
            default = "cloudflare";
            description = "caddy-dns provider name, used to select the right Caddy package";
          };

          # Email for Let's Encrypt account (acme-dns only)
          acmeEmail = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "you@example.com";
          };
        };

        # Services register here. Typically each service module sets its own
        # entry via config.my.modules.caddy.services.<name> so this module
        # stays decoupled.
        services = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              upstream = mkOption {
                type = types.str;
                description = "Backend address including scheme and port";
                example = "http://localhost:2283";
              };
              # Optional extra Caddy directives inserted into the site block.
              # Useful for WebSocket handling, custom headers, etc.
              extraConfig = mkOption {
                type = types.lines;
                default = "";
                example = ''
                  header Strict-Transport-Security "max-age=31536000"
                '';
              };
            };
          });
          default = {};
          description = "Services to expose, keyed by subdomain name";
        };
      };
    };

    config = with lib; let
      # Pick the right Caddy package
      caddyPkg =
        if cfg.tls.mode == "acme-dns"
        then
          pkgs.caddy.withPlugins {
            plugins = ["github.com/caddy-dns/${cfg.tls.dnsProvider}@latest"];
            hash = lib.fakeHash; # replace with real hash after first build
          }
        else pkgs.caddy;

      # TLS directive per site block
      tlsDirective =
        if cfg.tls.mode == "internal"
        then "tls internal"
        else ''
          tls {
            dns ${cfg.tls.dnsProvider} {env.CLOUDFLARE_AUTH_TOKEN}
            ${lib.optionalString (cfg.tls.acmeEmail != null) "issuer acme { email ${cfg.tls.acmeEmail} }"}
          }
        '';

      # Generate one site block per registered service
      siteBlocks = lib.concatStringsSep "\n\n" (
        lib.mapAttrsToList (name: svc: ''
          ${name}.${cfg.domain} {
            ${tlsDirective}
            reverse_proxy ${svc.upstream}
            ${lib.optionalString (svc.extraConfig != "") svc.extraConfig}
          }
        '')
        cfg.services
      );

      caddyfile = pkgs.writeText "Caddyfile" ''
        {
          # Disable the Caddy admin API on the public interface
          admin localhost:2019
          ${lib.optionalString (cfg.tls.mode == "internal") ''
          # Local CA — run `caddy trust` once per client to avoid cert warnings
          pki {
            ca local {
              name "Homelab Local CA"
            }
          }
        ''}
        }

        ${siteBlocks}
      '';
    in {
      services.caddy = {
        enable = true;
        package = caddyPkg;
        configFile = caddyfile;
      };

      # Inject DNS provider token when using acme-dns
      systemd.services.caddy.serviceConfig = lib.mkIf (cfg.tls.mode == "acme-dns") {
        EnvironmentFile = cfg.tls.secretsFile;
      };

      # Open firewall for HTTP and HTTPS
      networking.firewall.allowedTCPPorts = [80 443];
    };
  };
in {
  flake.modules.nixos.caddy = module;
}
