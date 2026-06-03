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

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
      loader = {
        grub.enable = false;
        systemd-boot.enable = false;
        generic-extlinux-compatible.enable = true;
      };
    };
  };
in {
  flake.modules.nixos.homelab = module;
}
