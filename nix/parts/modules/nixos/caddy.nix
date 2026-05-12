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
          description = "Tailscale domain e.g. berry.tail0fd3d1.ts.net";
        };
        lanDomain = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "berry.home";
          description = ''
            Optional LAN domain. When set, each service in `services` gets an
            additional plain HTTP (port 80) virtual host bound to `lanBindIp`
            at <service>.<lanDomain>. No TLS — intended for trusted LAN use.
          '';
        };
        lanBindIp = mkOption {
          type = types.str;
          default = "0.0.0.0";
          example = "192.168.1.63";
          description = "IP to bind the LAN HTTP vhosts to.";
        };

        authKeyFile = mkOption {
          type = types.nullOr types.path;
          default = "/etc/secrets/caddy-tailscale-env";
        };

        services = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              upstream = mkOption {
                type = types.str;
              };
              extraConfig = mkOption {
                type = types.lines;
                default = "";
              };
              lanExpose = mkOption {
                type = types.bool;
                default = true;
                description = "Expose this service on the LAN domain. Ignored when lanDomain is null.";
              };
            };
          });
          default = {};
        };
      };
    };

    config = with lib; let
      tailscaleSiteBlocks = lib.concatStringsSep "\n\n" (
        lib.mapAttrsToList (name: svc: ''
          ${name}.${cfg.domain} {
            bind tailscale/${name}
            reverse_proxy ${svc.upstream}
            ${lib.optionalString (svc.extraConfig != "") svc.extraConfig}
          }
        '')
        cfg.services
      );

      lanSiteBlocks = lib.optionalString (cfg.lanDomain != null) (
        lib.concatStringsSep "\n\n" (
          lib.mapAttrsToList (name: svc:
            lib.optionalString svc.lanExpose ''
              http://${name}.${cfg.lanDomain} {
                bind ${cfg.lanBindIp}
                reverse_proxy ${svc.upstream}
              }
            '')
          cfg.services
        )
      );
    in {
      users.users.caddy.extraGroups = ["tailscale"];
      services.tailscale.permitCertUid = "caddy";

      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/tailscale/caddy-tailscale@v0.0.0-20260106222316-bb080c4414ac"];
          hash = "sha256-t03XUYBJAYJkvJFQK8veN9SqHr9yZmvfxRYi7eA0174=";
        };
        virtualHosts = {};
        globalConfig = ''
          tailscale {
            auth_key {env.TS_AUTH_KEY}
          }
          servers {
            protocols h1 h2
          }
        '';
        extraConfig = tailscaleSiteBlocks + "\n\n" + lanSiteBlocks;
        environmentFile = cfg.authKeyFile;
      };

      networking.firewall.allowedTCPPorts =
        [80 443]
        ++ lib.optionals (cfg.lanDomain != null) [];
    };
  };
in {
  flake.modules.nixos.caddy = module;
}
