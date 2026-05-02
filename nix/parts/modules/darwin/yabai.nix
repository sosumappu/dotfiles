let
  module = {
    pkgs,
    lib,
    ...
  }: let
    inherit (pkgs) yabai;
  in {
    config = {
      my.user.packages = [yabai];

      services.yabai = {
        enable = true;
        package = yabai;
        enableScriptingAddition = true;
        extraConfig = builtins.readFile ../../../../config/yabai/yabairc;
      };

      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "yabai: loading scripting addition..."
        ${yabai}/bin/yabai --load-sa
      '';
    };
  };
in {
  flake = {
    modules = {
      darwin.yabai = module;
    };
  };
}
