LATEX = pdflatex
BIBTEX = bibtex

openbus.pdf : *.tex figs/*.pdf
	@$(LATEX) openbus.tex
	@$(BIBTEX) openbus
	@$(LATEX) openbus.tex

clean:
	@-rm *.swp
	@-rm *.log
	@-rm *.aux

clobber: clean
	@-rm openbus.pdf
