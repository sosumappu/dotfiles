if status is-interactive
  test -r '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/env_hook.fish' && source '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/env_hook.fish' > /dev/null 2> /dev/null; or true
end

test -r '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/variables.fish' && source '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/variables.fish' > /dev/null 2> /dev/null; or true
