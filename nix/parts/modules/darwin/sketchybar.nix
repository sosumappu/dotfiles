let
  module = {
    darwin
         = { pkgs, config, ... }: let
    inherit (config.my.user) home;
    inherit (config.home-manager.users."${config.my.username}") xdg;
    sketchybar = pkgs.sketchybar;
  in {
    config = {
      my.user.packages = with pkgs; [
        sketchybar
        sketchybar-app-font
        sbarlua
      ];

            launchd.user.agents.sketchybar = {
        serviceConfig.ProgramArguments = [ "${sketchybar}/bin/sketchybar" ];
        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = true;
        serviceConfig.EnvironmentVariables = {
          PATH = "${sketchybar}/bin:${config.environment.systemPath}";
        };
      };
    };
  };
        homeManager = _ : {
xdg.configFile."sketchybar" = {
        recursive = true;
        source = ../../../../config/sketchybar;
      };


        };
    };
in {
  flake = {modules = {darwin.sketchybar = module.darwin;
        homeManager.sketchybar = module.homeManager;
    }; };
}
