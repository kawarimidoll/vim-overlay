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

    vim-overlay = final: prev: {
      vim = prev.vim.overrideAttrs (oldAttrs: {
        version = "latest";
        src = vim-src;
        configureFlags =
          oldAttrs.configureFlags
          ++ [
            "--enable-terminal"
            "--with-compiledby=vim-overlay"
            "--enable-luainterp"
            "--with-lua-prefix=${prev.lua}"
            "--enable-fail-if-missing"
          ];
        buildInputs =
          oldAttrs.buildInputs
          ++ [prev.gettext prev.lua prev.libiconv];
      });
    };
  in {
    overlays.default = vim-overlay;

    packages = nixpkgs.lib.genAttrs systems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [vim-overlay];
        };
      in {
        vim = pkgs.vim;
        default = pkgs.vim;
      }
    );
  };
}
