let
  module = { pkgs, config, ... }: let
    inherit (config.my.user) home;
    inherit (config.home-manager.users."${config.my.username}") xdg;
    colima = pkgs.colima;
  in {
    config = {
        environment.variables =  {
            COLIMA_HOME = "${xdg.configFile}/colima";
            LIMA_HOME = "${xdg.dataHome}/lima";
        };
      my.user.packages = with pkgs; [
            colima
            docker-client
            docker-compose
      ];

      xdg.configFile."colima" = {
        recursive = true;
        source = ../../../../config/colima;
      };

      programs.zsh.shellAliases.dockerup = "colima start";
      launchd.daemons.colima-docker-compat = {
          script = ''
            # Wait for the docker socket to be created. This is important when
            # we enabled Colima and Docker compatability at the same time, for
            # the first time. Colima takes a while creating the VM.
            until [ -S ${config.homePath}/.colima/default/docker.sock ]
            do
              sleep 5
            done
            chmod g+rw ${config.homePath}/.colima/default/docker.sock
            ln -sf ${config.homePath}/.colima/default/docker.sock /var/run/docker.sock
          '';

            serviceConfig.RunAtLoad = true;
            serviceConfig.EnvironmentVariables = {
              PATH = "${colima}/bin:${config.environment.systemPath}";
            };

        };

      };
  };
in {
    flake.modules.darwin.colima = module;
}
