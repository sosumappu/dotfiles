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
          ${name}.${cfg.domain} {
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
        virtualHosts = {};
        extraConfig = siteBlocks;
      };

      networking.firewall.allowedTCPPorts = [80 443];
    };
  };
in {
  flake.modules.nixos.caddy = module;
}
