let
    module = {
  darwin= { pkgs, config, ... }: let
    inherit (config.my.user) home;
    inherit (config.home-manager.users."${config.my.username}") xdg;
    skhd = pkgs.skhd;
  in {
    config = {
      my.user.packages = [ skhd ];

      launchd.user.agents.skhd = {
        serviceConfig.ProgramArguments = [
          "${skhd}/bin/skhd"
          "-c" "${xdg.configHome}/skhd/skhdrc"
        ];
        serviceConfig.KeepAlive = true;
        serviceConfig.ProcessType = "Interactive";
        serviceConfig.EnvironmentVariables = {
          PATH = "${skhd}/bin:${config.environment.systemPath}";
        };
      };
    };
  };
        homeManager = _ : {
xdg.configFile."skhd/skhdrc" = {
        source = ../../../../config/skhd/skhdrc;
      };
        };
    };

in {
    flake =  {
    modules = {
    darwin.skhd = module.darwin;
        homeManager.skhd = module.homeManager;
    };
    };
}
