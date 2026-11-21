let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: let
      tex = pkgs.texlive.combine {
        inherit
          (pkgs.texlive)
          scheme-medium
          # Build & Linting tools
          latexmk
          chktex
          latexindent
          biber
          biblatex
          # Core Math, Analysis & Statistics
          amsmath
          amscls
          amsfonts
          mathtools
          thmtools
          physics
          siunitx
          bbm
          bm
          dsfont
          cancel
          mathrsfs
          stmaryrd
          # Figures, TikZ & Plots
          pgf
          pgfplots
          tikz-cd
          import
          xifthen
          pdfpages
          transparent
          caption
          subcaption
          float
          # Typography, French Mémoire & Cross-referencing
          babel-french
          microtype
          cleveref
          enumitem
          booktabs
          multirow
          geometry
          fancyhdr
          hyperref
          xcolor
          tcolorbox
          environ
          ;
      };
    in {
      config = with lib; {
        my.user.packages = with pkgs; [
          tex
          texlab
          ltex-ls-plus
          tex-fmt
          bibtex-tidy
        ];
      };
    };
  };
in {
  flake.modules.generic.tex = module.generic;
}
