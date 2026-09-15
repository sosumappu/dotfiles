{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      perSystem = {
        pkgs,
        system,
        ...
      }: {
        # This sets `pkgs` to a nixpkgs with allowUnfree option set.
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            (rWrapper.override {
              packages = with rPackages; [
                languageserver # R language server (R LSP client support)
                styler # formatter
                lintr # static linting, complements styler
                # add project-specific packages here, e.g. dplyr, ggplot2
              ];
            })
            rPackages.languageserver
          ];

          shellHook =
            /*
            bash
            */
            ''
              if [ ! -f main.R ]; then
                cat > main.R <<'EOF'
              # main.R
              main <- function() {
                message("Hello from R!")
              }

              if (sys.nframe() == 0) {
                main()
              }
              EOF
              fi

              if [ ! -f .Rprofile ]; then
                cat > .Rprofile <<'EOF'
              # Ensure styler/lintr are available in interactive sessions
              options(styler.colored_print.vertical = FALSE)
              EOF
              fi

              echo "Development environment ready!"
              echo "R: $(R --version | head -n1)"
            '';
        };
      };
    };
}
