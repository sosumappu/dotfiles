if [ -t 0 ]; then
  test -r '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/complete.sh' && . '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/complete.sh' > /dev/null 2> /dev/null || true

  test -r '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/env_hook.sh' && . '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/env_hook.sh' > /dev/null 2> /dev/null || true
fi

test -r '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/variables.sh' && . '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/variables.sh' > /dev/null 2> /dev/null || true
