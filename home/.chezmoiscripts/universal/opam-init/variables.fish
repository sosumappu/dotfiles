# Prefix of the current opam switch
set -gx OPAM_SWITCH_PREFIX '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default';
# Updated by package ocaml-base-compiler
set -gx CAML_LD_LIBRARY_PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/stublibs';
# Updated by package ocaml
set -gx CAML_LD_LIBRARY_PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/ocaml/stublibs:/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/ocaml';
# Updated by package ocaml
set -gx CAML_LD_LIBRARY_PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/stublibs':"$CAML_LD_LIBRARY_PATH";
# Updated by package ocaml
set -gx OCAML_TOPLEVEL_PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/toplevel';
# Binary dir for opam switch default
set -gx PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/bin' $PATH;
