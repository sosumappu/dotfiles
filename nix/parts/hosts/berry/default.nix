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
      username = "localhost";
      email = "adelarab.works@gmail.com";

      user = {
        isNormalUser = true;
        extraGroups = ["wheel" "networkmanager" "docker"];
      };

      modules = {
        caddy = {
          domain = "tail0fd3d1.ts.net";
          services = let
            common = ''
              tls {
              	 get_certificate tailscale
                     }
                     encode zstd gzip
                     header +X-Robots-Tag "noindex"
            '';
            mkService = upstream: {
              inherit upstream;
              extraConfig = common;
            };
          in {
            vault = mkService "http://127.0.0.1:${toString config.my.modules.vaultwarden.port}";
            immich = mkService "http://127.0.0.1:${toString config.my.modules.immich.port}";
            ntfy = mkService "http://127.0.0.1:${toString config.my.modules.ntfy.port}";
            prometheus = mkService "http://127.0.0.1:${toString config.my.modules.prometheus.port}";
            alertmanager = mkService "http://127.0.0.1:${toString config.my.modules.prometheus.alertmanager.port}";
            adguard = mkService "http://127.0.0.1:${toString config.my.modules.adguardhome.webPort}";
          };
        };

        adguardhome = {
          lanIp = "192.168.1.63";
          localDomain = "berry.home";
          autoRegisterCaddyServices = true;
        };

        vaultwarden = {
          domain = "vault.tail0fd3d1.ts.net";
        };

        immich = {
          mediaLocation = "/data/immich";
          settings = {
            newVersionCheck.enabled = false;
            trash = {
              enabled = true;
              days = 30;
            };
            storageTemplate = {
              enabled = true;
              template = "{{y}}/{{MM}}/{{filename}}";
            };
          };
        };

        ntfy = {
          baseUrl = "https://ntfy.tail0fd3d1.ts.net";
        };

        prometheus = {
          retentionTime = "30d";
        };
      };
    };

    services.restic.backups = let
      common = {
        repository = "s3:s3.eu-central-003.backblazeb2.com/berry-backups";
        passwordFile = "/etc/secrets/restic-password";
        environmentFile = "/etc/secrets/restic-env";
        pruneOpts = ["--keep-daily 7" "--keep-weekly 5" "--keep-monthly 12" "--keep-yearly 3"];
      };
    in {
      vaultwarden =
        common
        // {
          paths = ["/var/lib/bitwarden_rs"];
          backupPrepareCommand = "systemctl start vaultwarden-wal-flush || true";
          timerConfig = {
            OnCalendar = "03:00";
            Persistent = true;
          };
        };
      immich =
        common
        // {
          paths = ["/data/immich/backups"];
          timerConfig = {
            OnCalendar = "04:00";
            Persistent = true;
          };
        };
    };

    age.secrets.cloudflared-berry = {
      file = ../../../secrets/cloudflared.json.age;
      mode = "600";
    };

    nix = {
      settings."use-xdg-base-directories" = true;
      gc = {dates = "daily";};
      registry = {
        nixos.flake = inputs.nixpkgs;
        nixpkgs.flake = inputs.nixpkgs;
      };
    };

    boot.loader = {
      grub.enable = false;
      systemd-boot.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    networking = {
      hostName = "berry";
      wireless = {
        enable = true;
        secretsFile = "/etc/secrets/wifi.conf";
        networks."Almond wifi 2" = {
          pskRaw = "ext:psk_home";
        };
      };
      networkmanager.enable = false;
      interfaces.wlan0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "192.168.1.63";
            prefixLength = 24;
          }
        ];
      };
      defaultGateway = "192.168.1.254";
      nameservers = ["1.1.1.1"];
    };

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {LC_TIME = "en_GB.UTF-8";};
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
          ingress."berry" = "ssh://localhost:22";
          default = "http_status:404";
        };
      };

      avahi = {
        enable = true;
        nssmdns4 = true;
        publish = {
          enable = true;
          addresses = true;
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

    environment.shellAliases.l = pkgs.lib.mkForce null;

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

        "caddy"
        "adguardhome"
        "vaultwarden"
        "immich"
        "ntfy"
        "prometheus"
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
