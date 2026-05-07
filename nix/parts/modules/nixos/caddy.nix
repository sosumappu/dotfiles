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
            };
          });
          default = {};
        };
      };
    };

    config = with lib; let
      siteBlocks = lib.concatStringsSep "\n\n" (
        lib.mapAttrsToList (name: svc: ''
                 ${name}.${cfg.domain}{
          bind tailscale/${name}
                    reverse_proxy ${svc.upstream}
                    ${lib.optionalString (svc.extraConfig != "") svc.extraConfig}
                  }
        '')
        cfg.services
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
        extraConfig = siteBlocks;
        environmentFile = cfg.authKeyFile;
      };

      networking.firewall.allowedTCPPorts = [80 443];
    };
  };
in {
  flake.modules.nixos.caddy = module;
}
