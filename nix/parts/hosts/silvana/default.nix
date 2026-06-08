{inputs, ...}: let
  host = inputs.self.lib.mkNixos "x86_64-linux" "silvana";

  hostConfiguration = {
    pkgs,
    inputs,
    ...
  }: {
    imports = [
      ./hardware-configuration.nix
    ];

    my = {
      user = {
        isNormalUser = true;
        extraGroups = ["wheel" "networkmanager"];
      };
    };

    nix = {
      settings."use-xdg-base-directories" = true;
      gc = {dates = "daily";};
      autoOptimiseStore = true;
      registry = {
        nixos.flake = inputs.nixpkgs;
        nixpkgs.flake = inputs.nixpkgs;
      };
    };

    # Efi boot
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    networking = {
      hostName = "silvana";
      networkmanager.enable = true;
    };

    # VM / Memory tuning
    # ---------------------------------
    boot.kernel.sysctl = {
      "vm.swappiness" = 10; # Strongly prefer RAM over swap (default 60 causes swap-thrashing)
      "vm.vfs_cache_pressure" = 50; # Keep dentries/inodes cached longer
    };

    # Enable zram for compressed in-memory swap (much faster than disk swap)
    zramSwap = {
      enable = true;
      memoryPercent = 50; # Use up to 50% of RAM for compressed swap
      algorithm = "zstd";
      priority = 100; # Higher priority than disk swap (-2)
    };

    services = {
      nextdns.enable = true;
      printing.enable = true;
      openssh.enable = true;
      tailscale.enable = true;
      avahi.enable = true;
    };

    environment.systemPackages = with pkgs; [
      bitwarden-cli
      gnumake
      wget
      htop
      emacs
      mako
      killall
      feh
      unzip
      wirelesstools
      libnotify
    ];

    environment.shellAliases.l = pkgs.lib.mkForce null;

    programs = {
      gnupg.agent = {pinentryPackage = pkgs.pinentry-curses;};
      less.enable = true;
      mosh.enable = true;
      npm.enable = true;
      wireshark.enable = true;
    };
  };

  systemImports = [
    (inputs.self.lib.mkFeatureModule "nixos" {
      features = [
        "system-base"
        "shell"
        "git"
        "jujutsu"
        "ssh"
        "bat"
        "yazi"
        "ripgrep"
        "tmux"
        "misc"
        "node"
        "go"
        "rust"
        "python"
        "agenix"
        "vim"
        "gui"
        "ai"
        "gpg"
        "mail"
        "mpv"
        "kitty"
        "zk"
        "discord"
        "bun"
        "gaming"
        "ctos"
        "defaults"
      ];
    })
    hostConfiguration
  ];
in {
  flake.modules.nixos.silvana = {
    imports = systemImports;
  };

  flake.nixosConfigurations = host;
}
