let
  module = {config, ...}: let
    inherit (config.home-manager.users."${config.my.username}") xdg;
  in {
    config = {
      environment.variables = {
        RUSTUP_HOME = "${xdg.dataHome}/rustup";
        CARGO_HOME = "${xdg.dataHome}/cargo";
        MISE_CARGO_HOME = "$CARGO_HOME";
      };
    };
  };
in {
  flake.modules.generic.rust = module;
}
