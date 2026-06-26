let
  module = {
    nixos = {
      pkgs,
      lib,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;
      greetdConfig = pkgs.writeText "greeter.niri.kdl" ''
        spawn-sh-at-startup "CTOS_MODE=greetd quickshell --path ${xdg.configHome}/quickshell/greeter.qml"

         animations {
             off
         }

         hotkey-overlay {
             skip-at-startup
         }

         layout {
             background-color "#0E0E0E"
         }
      '';
    in {
      config = with lib; {
        my.user.packages = with pkgs; [
          wl-clipboard # Clipboard support
          wayland-utils # Wayland debugging tools
          wev # Key event viewer (useful for finding key names)
          wlr-randr # Output management
          xwayland-satellite # X11 app support (non-native on niri)
          dragon-drop # Drag and drop for wayland
          niri
          quickshell
          uwsm # for quickshell exit
        ];

        environment.sessionVariables = {
          NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland

          # XDG directories
          XDG_CURRENT_DESKTOP = "niri";
          XDG_SESSION_TYPE = "wayland";

          # For Qt apps
          QT_QPA_PLATFORM = "wayland";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

          # For SDL apps
          SDL_VIDEODRIVER = "wayland";
        };

        programs.niri = {
          enable = true;
          # NOTE: Using nixpkgs niri instead of niri-flake package due to upstream
          # build failures (issues #1501, #1515). The niri-flake's cargoInstallHook
          # fails silently during install phase.
          package = pkgs.niri;
        };

        services.dbus = {
          enable = true; # Required for niri wm
          packages = with pkgs; [nautilus];
        };

        xdg.portal = {
          enable = true;
          # wlr.enable = true; # DISABLED: wlr portal doesn't work with Niri
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
            # xdg-desktop-portal # DISABLED: already pulled in by the niri module
            # xdg-desktop-portal-wlr # DISABLED: Niri uses gnome portal for ScreenCast
            xdg-desktop-portal-termfilechooser # Portal for using TUIs as file pickers
          ];
        };

        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              # launch a niri instance to lockin greetd
              user = config.my.username;
              command = "${config.programs.niri.package}/bin/niri --config ${greetdConfig}";
            };
          };
        };
      };
    };
    homeManager = {
      pkgs,
      config,
      myConfig,
      ...
    }: let
      inherit (myConfig) username;
    in {
      xdg.configFile = {
        #  startup the bar
        "niri/conf.d/nix.kdl".text = ''
          spawn-at-startup "${pkgs.quickshell}/bin/quickshell --path ${config.home.homeDirectory}/.config/quickshell/bar.qml"
        '';
        "quickshell/greeter.config.json".text = ''
                            {
           "$schema": "https://raw.githubusercontent.com/TSM-061/ctOS/main/schema/greeter.schema.json",
           "user": "${username}",
            "monitor": "aged-cpm",
            "fontFamily": "Pragmata Pro",
            "fakeIdentity": {
              "id": "XYZ-843",
              "class": "L5_PROV",
              "fullName": "Aiden Snow"
            },
            "fakeStatus": {
              "env": "Workstation",
              "node": "109.389.013.301"
            },
            "modes": {
              "greetd": {
                "animations": "all",
                "exit": ["uwsm", "stop"],
                "launch":["uwsm", "start", "niri"]
              },
              "lockd": {
                "animations": "reduced"
              },
              "test": {
                "animations": "all"
              }
            }
          }
        '';
        "quickshell" = {
          recursive = true;
          source = ../../../../config/quickshell;
        };
        "niri" = {
          recursive = true;
          source = ../../../../config/niri;
        };
      };
    };
  };
in {
  flake.modules = {
    nixos.ctos = module.nixos;
    homeManager.ctos = module.homeManager;
  };
}
