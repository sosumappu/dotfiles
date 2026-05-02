{inputs, ...}: let
  host = inputs.self.lib.mkNixos "aarch64-linux" "berry";

  hostConfiguration = {
    pkgs,
    inputs,
    config,
    ...
  }: {
    imports = [
      ./hardware-configuration.nix
    ];

    my = {
      user = {
        isNormalUser = true;
        extraGroups = ["wheel" "networkmanager" "docker"];
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

    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;

    networking = {
      hostName = "berry";
      wireless.enable = true;
      networkmanager.enable = false;
      interfaces.wlan0.useDHCP = true;
    };

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {LC_TIME = "en_GB.UTF-8";};
    };

    age.secrets.cloudflared-berry = {
      file = ../../../secrets/cloudflared.json.age;
      mode = 600;
    };

    services = {
      openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };
      tailscale.enable = true;

      cloudflared = {
        enable = true;
        tunnels."f021ef4e-6386-450a-864e-f54e8c1ab427" = {
          credentialsFile = config.age.secrets.cloudflared-berry.path;
          "warp-routing".enabled = true;
          protocol = "quic";
          loglevel = "debug";
          ingress = {
            "berry" = "ssh://localhost:22";
          };
          default = "http_status:404";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      bitwarden-cli
      graphviz
      mermaid-cli
      git-filter-repo
      git-lfs
      git-sizer
      httpstat
      lazydocker
      llm-agents.gemini-cli
      entr
    ];

    environment.shellAliases.l = null;

    programs = {
      gnupg.agent = {pinentryPackage = pkgs.pinentry-curses;};
      less.enable = true;
      mosh.enable = true;
      npm.enable = true;
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
        "ai"
        "gpg"
        "zk"
        "bun"
      ];
    })
    hostConfiguration
  ];
in {
  flake.modules.nixos.berry = {
    imports = systemImports;
  };

  flake.nixosConfigurations = host;
}
