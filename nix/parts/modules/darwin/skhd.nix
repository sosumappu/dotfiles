let
  module = { pkgs, config, ... }: let
    inherit (config.my.user) home;
    inherit (config.home-manager.users."${config.my.username}") xdg;
    skhd = pkgs.skhd;
  in {
    config = {
      my.user.packages = [ skhd ];

      xdg.configFile."skhd/skhdrc" = {
        source = ../../../../config/skhd/skhdrc;
      };

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
in {
  flake.modules.darwin.skhd = module;
}
