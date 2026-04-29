let
    module = {
        darwin = {
            pkgs,
            lib,
            ...
        }: {
            config = with lib ; {
                my.user.packages = with pkgs; [zathura-with-plugins];
            };
        };
        nixos = {
            pkgs,
            lib,
            ...
        }: {
            config = with lib ; {
                my.user.packages = with pkgs; [zathura-with-plugins];
            };
        };
        homeManager = _: {
                xdg.configFile."zathura" = {
                    recursive = true;
                    source = ../../../../config/zathura;
                };
            };
    };
in {
    flake = {
        modules = {
            darwin.zathura = module.darwin;
            nixos.zathura = module.nixos;
            homeManager.zathura = module.homeManager;
        };
    };
}
