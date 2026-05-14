let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        environment.shellAliases.tmux = "direnv exec / tmux";

        my.user.packages = with pkgs; [
          tmux
        ];
      };
    };

    homeManager = _: {
      xdg.configFile."tmux" = {
        recursive = true;
        source = ../../../../config/tmux;
      };
      xdg.configFile."tmux-sessionizer" = {
        recursive = true;
        source = ../../../../config/tmux-sessionizer;
      };
    };
  };
in {
  flake = {
    modules = {
      generic.tmux = module.generic;
      homeManager.tmux = module.homeManager;
    };
  };
}
