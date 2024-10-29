if [[ -o interactive ]]; then
  [[ ! -r '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/complete.zsh' ]] || source '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/complete.zsh' > /dev/null 2> /dev/null

  [[ ! -r '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/env_hook.zsh' ]] || source '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/env_hook.zsh' > /dev/null 2> /dev/null
fi

[[ ! -r '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/variables.sh' ]] || source '/Users/localhost/.local/share/chezmoi/home/.chezmoiscripts/universal/opam-init/variables.sh' > /dev/null 2> /dev/null
