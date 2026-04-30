let
    module =  {
  darwin = { pkgs, config, ... }: let
    inherit (config.my.user) home;
    inherit (config.home-manager.users."${config.my.username}") xdg;
    colima = pkgs.colima;
  in {
    config = {
        environment.variables =  {
            COLIMA_HOME = "${xdg.configHome}/colima";
            LIMA_HOME = "${xdg.dataHome}/lima";
        };
      my.user.packages = with pkgs; [
            colima
            docker-client
            docker-compose
      ];

      launchd.daemons.colima-docker-compat = {
          script = ''
            # Wait for the docker socket to be created. This is important when
            # we enabled Colima and Docker compatability at the same time, for
            # the first time. Colima takes a while creating the VM.
            until [ -S ${home}/.colima/default/docker.sock ]
            do
              sleep 5
            done
            chmod g+rw ${home}/.colima/default/docker.sock
            ln -sf ${home}/.colima/default/docker.sock /var/run/docker.sock
          '';

            serviceConfig.RunAtLoad = true;
            serviceConfig.EnvironmentVariables = {
              PATH = "${colima}/bin:${config.environment.systemPath}";
            };

        };

      };
  };
        homeManager = _:  {
xdg.configFile."colima" = {
        recursive = true;
        source = ../../../../config/colima;
      };

        };
    };
in {
    flake = {
        modules = {
        darwin.colima = module.darwin;
        homeManager.colima = module.homeManager;
    };
    };

}
