let
  module = {pkgs, ...}: let
    inherit (pkgs) skhd;
  in {
    config = {
      my.user.packages = [skhd];

      services.skhd = {
        enable = true;
        skhdConfig = builtins.readFile ../../../../config/skhd/skhdrc;
      };
    };
  };
in {
  flake = {
    modules = {
      darwin.skhd = module;
    };
  };
}
