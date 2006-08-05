LATEX = latex

openbus.pdf : *.tex figs/*.pdf
	@$(LATEX) openbus.tex

clean:
	@-rm *.log
	@-rm *.aux

clobber: clean
	@-rm openbus.pdf
