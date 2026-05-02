let
  module = {
    darwin = {
      pkgs,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;
      inherit (pkgs) sketchybar sketchybar-app-font sbarlua;
    in {
      config = {
        my.user.packages = [sketchybar sketchybar-app-font sbarlua];

        launchd.user.agents.sketchybar = {
          path = [config.environment.systemPath];
          # script = "${sketchybar}/bin/sketchybar --config ${xdg.configHome}/sketchybar/sketchybarrc";
          serviceConfig.ProgramArguments = ["${sketchybar}/bin/sketchybar"];
          #   ++ [
          #     "--config"
          #     "${xdg.configHome}/sketchybar/sketchybarrc"
          #   ];
          serviceConfig.KeepAlive = true;
          serviceConfig.RunAtLoad = true;
          managedBy = "nix.modules.sketchybar";
        };
      };
    };

    homeManager = _: {
      xdg.configFile."sketchybar" = {
        recursive = true;
        source = ../../../../config/sketchybar;
      };
    };
  };
in {
  flake = {
    modules = {
      darwin.sketchybar = module.darwin;
      homeManager.sketchybar = module.homeManager;
    };
  };
}
