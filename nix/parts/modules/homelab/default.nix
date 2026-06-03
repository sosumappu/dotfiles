let
  module = {
    config,
    pkgs,
    inputs,
    ...
  }: {
    imports = [
      inputs.self.modules.nixos.immich
      inputs.self.modules.nixos.caddy
      inputs.self.modules.nixos.prometheus
      inputs.self.modules.nixos.vaultwarden
      inputs.self.modules.nixos.ntfy
    ];

    nix = {
      settings = {
        "use-xdg-base-directories" = true;
      };
      gc = {dates = "daily";};
      registry = {
        nixos.flake = inputs.nixpkgs;
        nixpkgs.flake = inputs.nixpkgs;
      };
    };
  };
in {
  flake.modules.nixos.homelab = module;
}
