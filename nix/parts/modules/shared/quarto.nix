let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;

      myRPackages = with pkgs.rPackages; [
        languageserver
        httpgd
        tidyverse
        GGally
        broom
        performance
        patchwork
        knitr
        rmarkdown
        here
        jsonlite
        devtools
        reticulate # wanted by quarto to execute Python when using R
      ];

      myPythonPackages = ps:
        with ps; [
          pandas
          numpy
          scipy
          statsmodels
          scikit-learn
          sympy
          matplotlib
        ];

      # See https://github.com/NixOS/nixpkgs/issues/519484#issuecomment-4667477454
      patchedQuarto =
        (pkgs.quarto.override {
          extraPythonPackages = myPythonPackages;
          extraRPackages = myRPackages;
        }).overrideAttrs (oldAttrs: {
          postPatch =
            (oldAttrs.postPatch or "")
            + ''
              substituteInPlace bin/quarto.js \
                --replace-fail "syntax-highlighting" "highlight-style"
            '';
        });
    in {
      config = with lib; {
        my.user.packages = with pkgs; [
          patchedQuarto
          (rWrapper.override {packages = myRPackages;})
        ];
      };
    };
  };
in {
  flake.modules.generic.quarto = module.generic;
}
