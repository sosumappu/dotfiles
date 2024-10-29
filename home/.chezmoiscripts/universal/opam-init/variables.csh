# Prefix of the current opam switch
if ( ! ${?OPAM_SWITCH_PREFIX} ) setenv OPAM_SWITCH_PREFIX ""
setenv OPAM_SWITCH_PREFIX '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default'
# Updated by package ocaml-base-compiler
if ( ! ${?CAML_LD_LIBRARY_PATH} ) setenv CAML_LD_LIBRARY_PATH ""
setenv CAML_LD_LIBRARY_PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/stublibs'
# Updated by package ocaml
if ( ! ${?CAML_LD_LIBRARY_PATH} ) setenv CAML_LD_LIBRARY_PATH ""
setenv CAML_LD_LIBRARY_PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/ocaml/stublibs:/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/ocaml'
# Updated by package ocaml
if ( ! ${?CAML_LD_LIBRARY_PATH} ) setenv CAML_LD_LIBRARY_PATH ""
setenv CAML_LD_LIBRARY_PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/stublibs':"$CAML_LD_LIBRARY_PATH"
# Updated by package ocaml
if ( ! ${?OCAML_TOPLEVEL_PATH} ) setenv OCAML_TOPLEVEL_PATH ""
setenv OCAML_TOPLEVEL_PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/lib/toplevel'
# Binary dir for opam switch default
if ( ! ${?PATH} ) setenv PATH ""
setenv PATH '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/default/bin':"$PATH"
