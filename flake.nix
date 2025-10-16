{
  description = "ghostty-gobject";

  inputs = {
    nixpkgs = {
      url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    };
    zon2nix = {
      url = "github:jcollie/zon2nix?ref=728e15a05e8f48765a64f74d5720ec0a2567fe95";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    zon2nix,
    ...
  }: let
    makePackages = system:
      import nixpkgs {
        inherit system;
      };
    forAllSystems = (
      function:
        nixpkgs.lib.genAttrs [
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-linux"
          "x86_64-darwin"
        ] (system: function (makePackages system))
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
              pkgs.nixfmt-rfc-style
              pkgs.pinact
              pkgs.pkg-config
              pkgs.zig_0_15
              zon2nix.packages.${pkgs.system}.zon2nix
            ]
            ++ gir_path;
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath gir_path;
          GIR_PATH = pkgs.lib.strings.makeSearchPathOutput "dev" "share/gir-1.0" gir_path;
        };
    });
  };
}
