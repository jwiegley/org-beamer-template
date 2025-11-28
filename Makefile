NAME    = org-beamer-template
PYTHON	= python
PRESENT	= /Applications/Misc/Présentation.app/Contents/MacOS/presentation.py
PDF	= $(NAME).pdf
EMACS   = emacs

all: $(PDF)

open: $(PDF)
	open $<

present: all
	$(PYTHON) $(PRESENT) $(PDF)

# Ensure all examples work before building the slide deck
%.tex: %.org Makefile
	$(EMACS) --debug-init -batch -L . -l support -f perform-extraction $<

%.pdf: %.tex
	xelatex -shell-escape -interaction nonstopmode $< || true
	xelatex -shell-escape -interaction nonstopmode $< || true
	xelatex -shell-escape -interaction nonstopmode $<
	@test -f $@ && echo "PDF generated successfully"

clean:
	rm -fr html
	rm -f *.tex *.pdf *.vrb *.aux *.log *.nav *.out *.snm *.toc *.upa
	rm -f src/*.d src/*.vo src/*.glob
	rm -fr _minted-* auto diagram*.svg svg-inkscape

watch:
	fswatch --batch-marker --latency 2 -m poll_monitor \
	    *.hs *.el *.org *.yaml Makefile \
	    | while read event; do \
	          [[ $$event == NoOp ]] && PATH=$(PWD):$(PATH) make; \
	      done
