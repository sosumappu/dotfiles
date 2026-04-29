let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;
    in {
      config = with lib; {
        environment.variables = {
          GRADLE_USER_HOME = "${xdg.dataHome}/gradle";
          MAVEN_USER_HOME  = "${xdg.dataHome}/maven";
          MAVEN_CONFIG     = "-gs ${xdg.configHome}/maven/settings.xml";
          MAVEN_ARGS       = "$MAVEN_CONFIG";
        };
        my.user.packages = with pkgs; [
          maven
          gradle
          ant
          temurin-bin-21
        ];
      };
    };

    homeManager = {
      inputs,
      config,
      pkgs,
      lib,
      ...
    }: {

      xdg.configFile."maven/settings.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <settings xmlns="http://maven.apache.org/SETTINGS/1.1.0"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
          <localRepository>${config.xdg.dataHome}/maven/repository</localRepository>
        </settings>
      '';
  };
    };
in {
  flake = {
    modules = {
      generic.java  = module.generic;
      homeManager.java = module.homeManager;
    };
  };
}
