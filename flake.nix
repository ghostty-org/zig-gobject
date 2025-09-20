{
  description = "ghostty-gobject";

  inputs = {
    nixpkgs = {
      url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    zon2nix = {
      url = "github:jcollie/zon2nix?ref=e626a6f501069e55ce3874a63527ddf867728ac8";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    nixpkgs,
    flake-utils,
    zon2nix,
    ...
  }: let
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        gir_path = [
          pkgs.gdk-pixbuf
          pkgs.gexiv2
          pkgs.glib
          pkgs.gobject-introspection
          pkgs.graphene
          pkgs.gtk4
          pkgs.harfbuzz
          pkgs.libadwaita
          pkgs.libpanel
          pkgs.libportal
          pkgs.libportal-gtk4
          pkgs.pango
          pkgs.librsvg
        ];
      in {
        devShells.default = pkgs.mkShell {
          name = "ghostty-gobject";
          packages =
            [
              pkgs.alejandra
              pkgs.gh
              pkgs.gnutar
              pkgs.libxml2
              pkgs.libxslt
              pkgs.minisign
              pkgs.nodePackages.prettier
              pkgs.pinact
              pkgs.pkg-config
              pkgs.zig_0_15
              zon2nix.packages.${system}.zon2nix
            ]
            ++ gir_path;
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath gir_path;
          GIR_PATH = pkgs.lib.strings.makeSearchPathOutput "dev" "share/gir-1.0" gir_path;
        };
      }
    );
}
