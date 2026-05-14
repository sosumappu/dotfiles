{inputs, ...}: let
  host = inputs.self.lib.mkDarwin "x86_64-darwin" "erdnase";

  hostConfiguration = {pkgs, ...}: {
    networking = {hostName = "erdnase";};

    my = {
      username = "localhost";
      email = "adelarab.works@gmail.com";
      website = "https://vinceromedia.co";
      company = "Vincero";
      devFolder = "code";
      modules = {
        mail = {
          accounts = [
            {
              name = "Work";
              email = "adel@vinceromedia.co";
              service = "gmail.com";
              mode = "remote";
              mbsync = {
                extra_exclusion_patterns = ''!"Version Control" !"Version Control/*" !GitHub !GitHub/* !"Inbox - CC" "!Inbox - CC/*" ![Gmail]* !Sent !Spam !Starred !Archive'';
              };
            }
          ];
        };
        syncthing = {
          peers = ["berry"];
          folders = {
            code = {
              path = "~/code";
              devices = ["berry"];
              type = "sendreceive";
            };
            sync = {
              path = "~/sync";
              devices = ["berry"];
              type = "sendreceive";
            };
          };
        };
      };
      user = {
        packages = with pkgs; [
          graph-easy
          graphviz
          mermaid-cli
          git-filter-repo
          git-lfs
          git-sizer
          httpstat
          k9s
          lazydocker
          llm-agents.gemini-cli
          entr
        ];
      };
    };

    homebrew = {
      taps = [
        "atlassian-labs/acli"
      ];

      casks = [
        "loom"
        "bitwarden"
        "docker-desktop"
        "ngrok"
        "figma"
        "visual-studio-code"
        "rawtherapee"
        "inkscape"
        "google-chrome"
        "cursor"
        "calibre"
        "garmin-express"
      ];

      brews = [
        "atlassian-labs/acli/acli"
      ];
    };
  };

  systemImports = [
    (inputs.self.lib.mkFeatureModule "darwin" {
      features = [
        "system-base"
        "defaults"
        "shell"
        "colima"
        "skhd"
        "yabai"
        "sketchybar"
        "git"
        "jujutsu"
        "ssh"
        "wezterm"
        "bat"
        "yazi"
        "ripgrep"
        "tmux"
        "misc"
        "node"
        "go"
        "rust"
        "java"
        "iac"
        "kubernetes"
        "unison"
        "python"
        "agenix"
        "vim"
        "gui"
        "ai"
        "gpg"
        "mail"
        "mpv"
        "kitty"
        "ghostty"
        "zk"
        "discord"
        "bun"
        "zathura"
        "syncthing"
      ];
    })
    hostConfiguration
  ];
in {
  flake.modules.darwin.erdnase = {
    imports = systemImports;
  };

  flake = {
    darwinConfigurations = host;
    erdnase = host.erdnase.system;
  };
}
