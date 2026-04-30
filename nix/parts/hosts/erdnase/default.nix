{inputs, ...}: let
  host = inputs.self.lib.mkDarwin "x86_64-darwin" "erdnase";

  hostConfiguration = {pkgs, ...}: {
    networking = {hostName = "erdnase";};
    ids.gids.nixbld = 30000;

    my = {
      username = "localhost";
      email = "adel@vinceromedia.co";
      website = "https://vinceromedia.co";
      company = "Vincero";
      devFolder = "dev";
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
        "bitwarden-cli"
        "docker-desktop"
        "ngrok"
        "figma"
        "visual-studio-code"
        "google-chrome"
        "cursor"
        "calibre"
      ];

      brews = [
        "acli"
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
