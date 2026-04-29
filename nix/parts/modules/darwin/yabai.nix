let
  module = { pkgs, config, ... }: let
    inherit (config.my.user) home;
    inherit (config.home-manager.users."${config.my.username}") xdg;
    yabai = pkgs.yabai;
  in {
    config = {
      my.user.packages = [ yabai ];

      home.file.".config/yabai/yabairc".source = ../../../../config/yabai/yabairc;

      launchd.user.agents.yabai = {
        serviceConfig.ProgramArguments = [
          "${yabai}/bin/yabai"
          "-c" "${xdg.configHome}/yabai/yabairc"
        ];
        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = true;
        serviceConfig.EnvironmentVariables = {
          PATH = "${yabai}/bin:${config.environment.systemPath}";
        };
      };

      launchd.daemons.yabai-sa = {
        serviceConfig.ProgramArguments = [
          "${yabai}/bin/yabai"
          "--load-sa"
        ];
        serviceConfig.RunAtLoad = true;
        serviceConfig.KeepAlive = { SuccessfulExit = false; };
      };

      environment.etc."sudoers.d/yabai".source = pkgs.runCommand "sudoers-yabai" {} ''
        YABAI_BIN="${yabai}/bin/yabai"
        SHASUM=$(sha256sum "$YABAI_BIN" | cut -d' ' -f1)
        cat <<EOF > "$out"
        %admin ALL=(root) NOPASSWD: sha256:$SHASUM $YABAI_BIN --load-sa
        EOF
      '';
    };
  };
in {
  flake.modules.darwin.yabai = module;
}
