# https://github.com/pabloagn/rhodium
let
  module = {
    pkgs,
    lib,
    config,
    inputs,
    ...
  }: {
    imports = [
      inputs.self.modules.nixos.audio
      inputs.self.modules.nixos.bluetooth
    ];

    config = with lib; {
      my.user.packages = with pkgs; [
        egl-wayland # required nvida utilities
        nvidia-vaapi-driver
        libvdpau-va-gl
        xorg.xev #xorg key registry
      ];
      # Add these kernel modules
      boot.initrd.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
      boot.kernelModules = [
        "kvm-intel"
      ];

      # NVIDIA drivers package (use the stable version)
      hardware.nvidia = {
        open = false; # Use open kernel modules for Turing or later GPUs (RTX series)
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        powerManagement.enable = true; # Enable power management (suspend/resume)
        modesetting.enable = true;
      };

      hardware.nvidia-container-toolkit = {
        enable = true;
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      i18n.defaultLocale = "en_GB.UTF-8"; # Locale

      # Additional properties
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_GB.UTF-8";
        LC_IDENTIFICATION = "en_GB.UTF-8";
        LC_MEASUREMENT = "en_GB.UTF-8";
        LC_MONETARY = "en_GB.UTF-8";
        LC_NAME = "en_GB.UTF-8";
        LC_NUMERIC = "en_GB.UTF-8";
        LC_PAPER = "en_GB.UTF-8";
        LC_TELEPHONE = "en_GB.UTF-8";
        LC_TIME = "en_GB.UTF-8";
      };

      console = {
        font = "CaskaydiaCove Nerd Font";
        keyMap = "fr"; # Default console Keymap
      };

      services.xserver.xkb = {
        layout = "fr";
        variant = "";
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct"; # For hardware video acceleration
        ELECTRON_OZONE_PLATFORM_HINT = "auto"; # Electron app flickering fix
        NIXOS_OZONE_WL = "1"; # Auto configure Electron apps for Wayland
      };

      # Enable NVIDIA settings
      services.xserver.videoDrivers = ["nvidia"];

      # Enable Wayland compatibility with Electron
      #services.xserver.displayManager.wayland.enable = true;
    };
  };
in {
  flake.modules.nixos.defaults = module;
}
