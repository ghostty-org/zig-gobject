{
  description = "ghostty-gobject";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }: let
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        gir_paths = [
          pkgs.gdk-pixbuf
          pkgs.glib
          pkgs.gobject-introspection
          pkgs.graphene
          pkgs.gtk4
          pkgs.harfbuzz
          pkgs.libadwaita
          pkgs.pango
        ];
      in {
        devShells.default = pkgs.mkShell {
          name = "ghostty-gobject";
          nativeBuildInputs = [
            pkgs.zig_0_13
            pkgs.libxslt
            pkgs.libxml2
            pkgs.alejandra
          ];
          shellHook = ''
            export GIR_PATH="${pkgs.lib.strings.makeSearchPathOutput "dev" "share/gir-1.0" gir_paths}"
          '';
        };
      }
    );
}
