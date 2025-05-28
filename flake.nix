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

      ignoredDirs = [
        "html" ".diagrams_cache" "_minted-org-beamer-template"
        "auto" "dist" "svg-inkscape"
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
        liberation_ttf
        (emacs.pkgs.withPackages(epkgs: with epkgs; [
          org
          ob-diagrams
        ]))
      ];
    in rec {
      packages.presentation = with pkgs; stdenv.mkDerivation rec {
        name = "org-beamer-template";
        version = "1.0";

        src =
          if lib.inNixShell
          then null
          else filterSource ./.;

        inherit buildInputs;
        enableParallelBuilding = true;

        buildPhase = ''
          export OSFONTDIR=${pkgs.liberation_ttf}/share/fonts
          make
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

      defaultPackage = packages.presentation;
    });
}
