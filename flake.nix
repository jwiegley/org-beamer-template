{
  description = "org-beamer template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      version = builtins.substring 0 8 self.lastModifiedDate;
      pkgs = import nixpkgs { inherit system; };

      texFull = pkgs.texlive.combine {
        inherit (pkgs.texlive)
          scheme-full texdoc latex2e-help-texinfo xetex fontspec;
        pkgFilter = pkg:
          pkg.tlType == "run"
            || pkg.tlType == "bin"
            || pkg.pname == "latex2e-help-texinfo";
      };

      # Emacs with packages - use nix packages instead of ELPA to avoid download issues
      myEmacs = pkgs.emacs30.pkgs.withPackages (epkgs: with epkgs; [
        ob-diagrams
      ]);

      ignoredDirs = [
        "html" ".diagrams_cache" "_minted-org-beamer-template"
        "auto" "dist" "svg-inkscape" "_minted"
      ];

      ignoredSuffixes = [
        ".aux" ".cabal" ".log" ".nav" ".out" ".pdf" ".snm" ".svg"
        ".tex" ".toc" ".upa" ".vrb"
      ];

      filterSource = src: with pkgs.lib; cleanSourceWith {
        inherit src;
        filter = path: type:
        let baseName = baseNameOf path; in
           !( type == "directory"
              && builtins.elem baseName ([".git"] ++ ignoredDirs))
        &&
           !( type == "unknown"
              || baseName == "result"
              || any (suf: hasSuffix suf path) ignoredSuffixes);
      };

      buildInputs = with pkgs; [
        texFull
        plantuml
        ditaa
        graphviz  # for dot diagrams
        liberation_ttf
        inkscape  # for SVG to PDF conversion
        myEmacs
        jdk       # Java for plantuml and ditaa
      ];

      # Fontconfig configuration to find Liberation fonts
      fontsConf = pkgs.makeFontsConf {
        fontDirectories = [ pkgs.liberation_ttf ];
      };
    in rec {
      packages.presentation = with pkgs; stdenv.mkDerivation rec {
        name = "org-beamer-template";
        version = "1.0";

        src =
          if lib.inNixShell
          then null
          else filterSource ./.;

        inherit buildInputs;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        enableParallelBuilding = true;

        buildPhase = ''
          export FONTCONFIG_FILE=${fontsConf}
          export OSFONTDIR=${pkgs.liberation_ttf}/share/fonts
          export HOME=$(mktemp -d)
          export XDG_CACHE_HOME=$HOME/.cache
          export XDG_CONFIG_HOME=$HOME/.config
          export XDG_DATA_HOME=$HOME/.local/share
          mkdir -p $HOME/.cache $HOME/.config $HOME/.local/share
          make EMACS=${myEmacs}/bin/emacs
        '';
        installPhase = ''
          mkdir -p $out/share/pdf
          cp -p org-beamer-template.pdf $out/share/pdf
        '';

        env = buildEnv {
          inherit name;
          paths = buildInputs;
        };
      };

      packages.default = packages.presentation;

      # Development shell for interactive work
      devShells.default = pkgs.mkShell {
        inherit buildInputs;
        shellHook = ''
          export FONTCONFIG_FILE=${fontsConf}
          export OSFONTDIR=${pkgs.liberation_ttf}/share/fonts
          echo "org-beamer-template development environment"
          echo "Run 'make' to build the presentation"
        '';
      };
    });
}
