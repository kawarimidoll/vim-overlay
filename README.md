# vim-overlay

Nix flake to install Vim head

https://github.com/vim/vim

## use in flake

Apply `vim-overlay.overlays.default`. Then the latest Vim will be installed.

Here is sample flake:

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
    # set your system
    system = "aarch64-darwin";

    pkgs = import nixpkgs {
      inherit system;
      overlays = [vim-overlay.overlays.default];
    };
  in {
    packages.${system}.default = nixpkgs.legacyPackages.${system}.buildEnv {
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

### configuration

To use specific features, call `vim-overlay.overlays.features` and apply
arguments.

```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [
    (vim-overlay.overlays.features {
      compiledby = "nix-vim";
      lua = true;
      ruby = true;
    })
  ];
};
```

| name       | default       | description                             |
| ---------- | ------------- | --------------------------------------- |
| compiledby | "vim-overlay" | change "Compiled by" in `vim --version` |
| cscope     | false         | enable +cscope feature                  |
| lua        | false         | enable +lua feature                     |
| python3    | false         | enable +python3 feature                 |
| ruby       | false         | enable +ruby feature                    |
| sodium     | false         | enable +sodium feature                  |

## develop

Run below to enable pre-commit hook.

```
nix develop
```

Run below to build locally.

```
nix build
```
