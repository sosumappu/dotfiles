let
  module = let
    commonModule = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        environment = {
          shellAliases.e = "$EDITOR";

          systemPackages = with pkgs; [
            vim
            neovim-unwrapped
          ];
        };

        environment.variables = {
          EDITOR = "${lib.getExe pkgs.neovim-unwrapped}";
          VISUAL = "$EDITOR";
          GIT_EDITOR = "$EDITOR";
          MANPAGER = "$EDITOR +Man!";
          JAVA_DEBUG_PATH = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}";
          JAVA_TEST_PATH = "${pkgs.vscode-extensions.vscjava.vscode-java-test}";
        };

        my.user.packages = with pkgs; [
          fzf
          fd
          ripgrep
          hadolint
          dotenv-linter
          alejandra
          shellcheck
          shfmt
          stylua
          vscode-langservers-extracted
          prettier
          bash-language-server
          dockerfile-language-server
          docker-compose-language-service
          vtsls
          yaml-language-server
          tailwindcss-language-server
          statix
          lua-language-server
          tree-sitter
          nixd
          taplo
          typos
          typos-lsp
          markdown-oxide
          copilot-language-server
          stylelint-lsp
          cppcheck
          mypy
          rust-analyzer
          clang-tools
        ];
      };
    };

    nixosModule = {pkgs, ...}: {
      imports = [commonModule];

      config = {
        environment.systemPackages = with pkgs; [gcc];
      };
    };
  in {
    darwin = commonModule;

    nixos = nixosModule;

    homeManager = {
      lib,
      pkgs,
      config,
      myConfig,
      ...
    }: {
      # Link the config out of the store so it stays live-editable without
      # a rebuild.
      xdg.configFile."nvim".source =
        config.lib.file.mkOutOfStoreSymlink "${myConfig.dotfilesDir}/config/nvim";

      # Pin upstream dictionaries separately from spell.add, which remains
      # writable and contains the user's accepted words.
      xdg.dataFile =
        lib.mapAttrs'
        (name: hash: {
          name = "nvim/site/spell/${name}";
          value.source = pkgs.fetchurl {
            inherit name hash;
            urls = [
              "https://ftp.nluug.nl/pub/vim/runtime/spell/${name}"
              "https://ftp.fu-berlin.de/pub/unix/editors/vim/runtime/spell/${name}"
            ];
          };
        })
        {
          "en.utf-8.spl" = "sha256-/sq9yUm2o50ywImfolReqyXmPy7QozxK0VEUJjhNMHA=";
          "en.utf-8.sug" = "sha256-W25eYWVYLS/Xob+kH7zoJCxyR2IixV0XwqorqTPJMuw=";
          "fr.utf-8.spl" = "sha256-q/uXArmNiHwXWs5Y8as5cz3AjQO2dNkU9WNE74bmO2E=";
          "fr.utf-8.sug" = "sha256-ApS8MrQskLuyhqieI8o3c7fvUO/xq1I7FRPWolxrP1g=";
        };

      home.activation.vim = lib.hm.dag.entryAfter ["writeBoundary"] ''
        echo ":: -> Running vim home-manager activation..."
        mkdir -p ${config.xdg.stateHome}/nvim/{backup,swap,undo,view}
      '';
    };
  };
in {
  flake = {
    modules = {
      darwin.vim = module.darwin;
      nixos.vim = module.nixos;
      homeManager.vim = module.homeManager;
    };
  };
}
