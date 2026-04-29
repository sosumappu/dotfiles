let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        environment.variables.UNISON = "${xdg.dataHome}/unison";
        my.user.packages = with pkgs; [
          unison
        ];
      };
    };

    homeManager = _: {
      xdg.dataHome."unison" = {
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
