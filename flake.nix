{
  description = "Vim overlay flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    vim-src = {
      url = "github:vim/vim";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    vim-src,
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    make-overlay = {
      compiledby ? "vim-overlay",
      cscope ? false,
      lua ? false,
      # perl ? false, # fail to build...
      python3 ? false,
      ruby ? false,
      sodium ? false,
    }: final: prev: {
      vim = prev.vim.overrideAttrs (oldAttrs: {
        version = "latest";
        src = vim-src;
        configureFlags =
          (oldAttrs.configureFlags or [])
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

        nativeBuildInputs =
          (oldAttrs.nativeBuildInputs or [])
          ++ [prev.pkg-config];

        buildInputs =
          (oldAttrs.buildInputs or [])
          ++ [prev.ncurses prev.glib]
          ++ prev.lib.optional lua prev.lua
          ++ prev.lib.optional python3 prev.python3
          ++ prev.lib.optional ruby prev.ruby
          # ++ prev.lib.optional perl prev.perl
          ++ prev.lib.optional sodium prev.libsodium;
      });
    };

    vim-overlays = {
      default = make-overlay {};
      features = make-overlay;
    };
  in {
    overlays = vim-overlays;

    # packages = nixpkgs.lib.genAttrs systems (
    #   system: let
    #     pkgs = import nixpkgs {
    #       inherit system;
    #       overlays = [vim-overlays.default];
    #     };
    #   in {
    #     vim = pkgs.vim;
    #     default = pkgs.vim;
    #   }
    # );
  };
}