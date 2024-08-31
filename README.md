# vim-overlay

Nix flake to install Vim head

https://github.com/vim/vim

## use in flake

```nix
{
  description = "Minimal package definition to use vim-overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    vim-overlay.url = "github:kawarimidoll/vim-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    vim-overlay,
  }: let
    system = "aarch64-darwin";

    pkgs = import nixpkgs {
      inherit system;
      overlays = [vim-overlay.overlays.default];
    };
  in {
    packages.aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.buildEnv {
      name = "my-packages";
      paths = with pkgs; [
        vim
      ];
    };
  };
}
```

```
$ nix build
$ ./result/bin/vim --version
```
