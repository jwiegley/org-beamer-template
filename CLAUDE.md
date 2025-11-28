# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Org-mode Beamer presentation template that converts `.org` files to LaTeX Beamer slides (PDF). It supports embedded diagrams (PlantUML, Ditaa, Graphviz/dot, TikZ) and code extraction from Haskell test files.

## Build Commands

```bash
# Build the PDF presentation
make

# Build and open the PDF
make open

# Build and present (requires Présentation.app)
make present

# Clean all generated files
make clean

# Watch for changes and rebuild automatically
make watch
```

## Build Pipeline

1. `org-beamer-template.org` → `org-beamer-template.tex` (via Emacs batch mode with `support.el`)
2. `org-beamer-template.tex` → `org-beamer-template.pdf` (via xelatex, run 3 times)

The Emacs step runs `perform-extraction` which:
- Processes `### Part.Chapter.Section.Test` markers to extract code from `Main.hs` test definitions
- Exports the org file to LaTeX using ox-beamer

## Key Files

- `org-beamer-template.org` - Main presentation source
- `support.el` - Emacs Lisp for org-babel setup and code extraction
- `Main.hs` - Haskell test file; code blocks referenced via `### path.to.test` markers are extracted into slides
- `bae-beamer-theme/` - Custom Beamer theme files

## Nix Development

The project uses a Nix flake for reproducible builds with all dependencies (texlive-full, plantuml, ditaa, emacs with org-mode).

```bash
# Build with Nix
nix build

# Enter development shell
nix develop
```

## Diagram Support

The template supports several diagram types via org-babel:
- PlantUML (`.svg` output)
- Ditaa (`.svg` output)
- Graphviz/dot (`.svg` output)
- TikZ-cd (inline LaTeX)

SVG diagrams are converted to PDF via Inkscape for inclusion in the final document.
