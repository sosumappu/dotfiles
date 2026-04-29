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
        environment.variables.RIPGREP_CONFIG_PATH = "${xdg.configHome}/ripgrep/config";
        my.user.packages = with pkgs; [
                        terraform
                        tflint
                        sops
                        shellcheck
                        terragrunt
                    ];
      };
    };
  };
in {
  flake = {
    modules = {
      generic.iac = module.generic;
    };
  };
}
