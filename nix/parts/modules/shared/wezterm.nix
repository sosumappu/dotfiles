let
    module = {
        darwin = _: {
            config = {
                homebrew.casks = ["wezterm"];
            };
        };

        nixos = {
            pkgs,
            lib,
            ...
        }: {
                config = with lib; {
                    my.user.packages = with pkgs; [wezterm];
                };
        };

        homeManager = _: {
            xdg.configFile."wezterm" = {
                recursive = true;
                source = "../../../../config/wezterm";
            };
        };
    };
in {
    flake = {
        modules = {
            darwin.wezterm = module.darwin;
            nixos.wezterm = module.nixos;
            homeManager.wezterm = module.homeManager;
        };
    };
}
