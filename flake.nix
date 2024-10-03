{
  description = "LaTeX environment and Yoneda lemma PDF builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: let
        texEnv = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            catchfile
            fvextra
            framed
            newtx
            nowidow
            emptypage
            wrapfig
            subfigure
            adjustbox
            collectbox
            tikz-cd
            imakeidx
            idxlayout
            titlesec
            subfiles
            lettrine
            upquote
            scheme-medium
            listings
            minted
            microtype
            babel
            todonotes
            chngcntr
            ifplatform
            xstring
            enumitem;
        };

        commonEnv = {
          FONTCONFIG_FILE = pkgs.makeFontsConf {
            fontDirectories = with pkgs; [
              inconsolata-lgc
              libertine
              libertinus
            ];
          };
          buildInputs = with pkgs; [
            texEnv
            gnumake
            python3Packages.pygments
            which
          ];
        };

        yonedaPdf = pkgs.stdenvNoCC.mkDerivation {
          name = "yoneda-pdf";
          src = ./.;

          buildInputs = commonEnv.buildInputs;

          FONTCONFIG_FILE = commonEnv.FONTCONFIG_FILE;

          buildPhase = ''
            export HOME=$TMPDIR
            pdflatex -shell-escape -interaction=nonstopmode yoneda.tex
            pdflatex -shell-escape -interaction=nonstopmode yoneda.tex
          '';

          installPhase = ''
            mkdir -p $out
            cp yoneda.pdf $out/
          '';
        };
      in {
        # The default package is now the PDF
        packages.default = yonedaPdf;

        # Keep the development environment
        devShells.default = pkgs.mkShell commonEnv;
      };
    };
}
