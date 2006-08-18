LATEX = pdflatex
BIBTEX = bibtex

openbus.pdf : *.tex figs/*.pdf
	@$(LATEX) openbus.tex
	@$(BIBTEX) openbus
	@$(LATEX) openbus.tex

clean:
	@rm -f *.swp *.log *.aux *.bbl *.blg >& /dev/null

clobber: clean
	@-rm openbus.pdf
