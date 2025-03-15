{
  description = "ghostty-gobject";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
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
          packages =
            [
              pkgs.alejandra
              pkgs.gh
              pkgs.gnutar
              pkgs.libxml2
              pkgs.libxslt
              pkgs.nodePackages.prettier
              pkgs.pkg-config
              pkgs.zig_0_14
              zon2nix.packages.${system}.zon2nix
            ]
            ++ gir_path;
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath gir_path;
          shellHook = ''
            export GIR_PATH=${pkgs.lib.strings.makeSearchPathOutput "dev" "share/gir-1.0" gir_path}
          '';
        };
        packages.default = let
          zig_hook = pkgs.zig_0_14.hook.overrideAttrs {
            zig_default_flags = "--color off";
          };
        in
          pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "ghostty-gobject";
            version = "0.2.0";
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.intersection (pkgs.lib.fileset.fromSource (pkgs.lib.sources.cleanSource ./.)) (
                pkgs.lib.fileset.unions [
                  ./build.zig
                  ./build.zig.zon
                  ./build.zig.zon.nix
                  ./gir-fixes
                ]
              );
            };
            deps = pkgs.callPackage ./build.zig.zon.nix {
              name = "${finalAttrs.pname}-cache-${finalAttrs.version}";
            };
            GIR_PATH = pkgs.lib.strings.makeSearchPathOutput "dev" "share/gir-1.0" gir_path;
            nativeBuildInputs = [
              zig_hook
              pkgs.libxslt
            ];
            zigBuildFlags = [
              "--system"
              "${finalAttrs.deps}"
            ];
          });
        apps.release = let
          release = pkgs.writeTextFile {
            name = "release";
            destination = "/bin/release";
            text = pkgs.lib.concatStringsSep "\n" [
              ''
                #!${pkgs.lib.getExe pkgs.nushell}

                alias zig = ^${pkgs.lib.getExe pkgs.zig_0_14}
                alias nix = ^${pkgs.lib.getExe pkgs.nix}
                alias tar = ^${pkgs.lib.getExe pkgs.gnutar}
                alias gh = ^${pkgs.lib.getExe pkgs.gh}
                alias ln = ^${pkgs.uutils-coreutils}/bin/uutils-ln
                alias readlink = ^${pkgs.uutils-coreutils}/bin/uutils-readlink
                alias gzip = ^${pkgs.lib.getExe pkgs.gzip}
                alias zstd = ^${pkgs.lib.getExe pkgs.zstd}
              ''
              (builtins.readFile ./release.nu)
            ];
            executable = true;
          };
        in {
          type = "app";
          program = "${pkgs.lib.getExe release}";
        };
      }
    );
}
