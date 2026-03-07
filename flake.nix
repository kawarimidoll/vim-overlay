{
  description = "Vim overlay flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vim-src = {
      url = "github:vim/vim";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      vim-src,
      git-hooks,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      make-overlay =
        {
          compiledby ? "vim-overlay",
          cscope ? false,
          lua ? false,
          # perl ? false, # fail to build...
          python3 ? false,
          ruby ? false,
          sodium ? false,
        }:
        final: prev: {
          vim = prev.vim.overrideAttrs (oldAttrs: {
            version = "latest";
            src = vim-src;
            configureFlags =
              (oldAttrs.configureFlags or [ ])
              ++ [
                "--with-compiledby=${compiledby}"
                "--enable-fail-if-missing"
              ]
              ++ prev.lib.optionals lua [
                "--with-lua-prefix=${prev.lua}"
                "--enable-luainterp"
              ]
              ++ prev.lib.optionals python3 [
                "--enable-python3interp=yes"
                "--with-python3-command=${prev.python3}/bin/python3"
                "--with-python3-config-dir=${prev.python3}/lib"
                # Disable python2
                "--disable-pythoninterp"
              ]
              # ++ prev.lib.optional perl "--enable-perlinterp"
              ++ prev.lib.optionals ruby [
                "--with-ruby-command=${prev.ruby}/bin/ruby"
                "--enable-rubyinterp"
              ]
              ++ prev.lib.optional cscope "--enable-cscope";

            nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];

            buildInputs =
              (oldAttrs.buildInputs or [ ])
              ++ [
                prev.ncurses
                prev.glib
              ]
              ++ prev.lib.optional lua prev.lua
              ++ prev.lib.optional python3 prev.python3
              ++ prev.lib.optional ruby prev.ruby
              # ++ prev.lib.optional perl prev.perl
              ++ prev.lib.optional sodium prev.libsodium;
          });
        };

      default-overlay = make-overlay { };
    in
    {
      overlays.default = default-overlay;

      lib.features = make-overlay;

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # Nix
              nixfmt.enable = true;

              # Conventional Commits (commit-msg stage)
              convco = {
                enable = true;
                entry =
                  let
                    script = pkgs.writeShellScript "convco-check" ''
                      msg=$(head -1 "$1")
                      # Skip git-generated messages (fixup/squash/amend/revert)
                      re='^(fixup|squash|amend)! |^Revert "'
                      if [[ "$msg" =~ $re ]]; then
                        exit 0
                      fi
                      ${pkgs.lib.getExe pkgs.convco} check --from-stdin < "$1"
                    '';
                  in
                  builtins.toString script;
              };

              # Markdown / YAML (fast alternative to prettier)
              dprint = {
                enable = true;
                name = "dprint";
                entry = "${pkgs.dprint}/bin/dprint fmt --diff";
                types = [
                  "markdown"
                  "yaml"
                ];
                pass_filenames = false;
              };

              # YAML (GitHub Actions)
              actionlint.enable = true;
              zizmor.enable = true;

              # Spell check (Rust-based, fast)
              typos.enable = true;

              # Security
              check-merge-conflicts.enable = true;
              detect-private-keys.enable = true;

              # File hygiene
              check-case-conflicts.enable = true;
              end-of-file-fixer.enable = true;
              trim-trailing-whitespace.enable = true;
            };
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          pre-commit-check = self.checks.${system}.pre-commit-check;
        in
        {
          default = pkgs.mkShell {
            inherit (pre-commit-check) shellHook;
            buildInputs = pre-commit-check.enabledPackages;
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ default-overlay ];
          };
        in
        {
          vim = pkgs.vim;
          default = pkgs.vim;
        }
      );
    };
}
