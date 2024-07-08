{
  description = "auto-pandoc.nvim flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }: let
    name = "auto-pandoc.nvim";

    plugin-overlay = import ./nix/plugin-overlay.nix {
      inherit name self;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
        ci-overlay = import ./nix/ci-overlay.nix {
          inherit self name;
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            plugin-overlay
            ci-overlay
          ];
        };

        devShell = pkgs.mkShell {
          buildInputs = let
            nvim-test = pkgs.writeShellApplication {
              name = "nvim-test";
              text = let
                test-cache-dir = "~/.cache/auto-pandoc";
              in
                # bash
                ''
                  ${pkgs.coreutils}/bin/rm -rf ${test-cache-dir}
                  ${pkgs.coreutils}/bin/mkdir -p ${test-cache-dir}
                  ${pkgs.neovim-with-plugin}/bin/nvim -c "e test/files/test.md"
                '';
            };
          in [
            pkgs.luajit
            nvim-test
          ];
        };
      in {
        devShells = {
          default = devShell;
          inherit devShell;
        };

        packages = rec {
          default = auto-pandoc-nvim;
          inherit (pkgs.luajitPackages) auto-pandoc-nvim;
          inherit (pkgs) neovim-with-plugin;
        };
      };
      flake = {
        overlays.default = plugin-overlay;
      };
    };
}
