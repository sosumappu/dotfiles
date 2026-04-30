let
  module = {
    generic = {
            config,
      pkgs,
      lib,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;
    in {
      config = with lib; {
        environment.variables.UNISON = "${xdg.dataHome}/unison";
        my.user.packages = with pkgs; [
          unison
        ];
      };
    };

    homeManager = _: {
      xdg.dataFile."unison" = {
        recursive = true;
        source = ../../../../config/unison;
      };
     };
  };
in {
  flake = {
    modules = {
      generic.unison = module.generic;
      homeManager.unison = module.homeManager;
    };
  };
}
