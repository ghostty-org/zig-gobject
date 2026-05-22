{
  description = "ghostty-gobject";

  inputs = {
    nixpkgs = {
      url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    };
    zon2nix = {
      url = "github:jcollie/zon2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    zon2nix,
    ...
  }: let
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    makePackages = system:
      import nixpkgs {
        inherit system;
      };
    forAllSystems = (
      function:
        nixpkgs.lib.genAttrs platforms (system: function (makePackages system))
    );
  in {
    devShells = forAllSystems (pkgs: {
      default = let
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
          pkgs.librsvg
          pkgs.nautilus
          pkgs.pango
        ];
      in
        pkgs.mkShell {
          name = "ghostty-gobject";
          packages =
            [
              pkgs.gh
              pkgs.gnutar
              pkgs.libxml2
              pkgs.libxslt
              pkgs.minisign
              pkgs.nixfmt
              pkgs.nix-prefetch-git
              pkgs.pinact
              pkgs.pkg-config
              pkgs.zig_0_16
              zon2nix.packages.${pkgs.stdenv.hostPlatform.system}.zon2nix
            ]
            ++ gir_path;
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath gir_path;
          GIR_PATH = pkgs.lib.strings.makeSearchPathOutput "dev" "share/gir-1.0" gir_path;
        };
    });
  };
}
