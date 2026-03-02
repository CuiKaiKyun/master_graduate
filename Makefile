# Makefile for LaTeX project
TEX = xelatex
BIB = bibtex
TEXFLAGS = -synctex=1 -interaction=nonstopmode
OUTPUTDIR = output
BUILDDIR = build
MAIN = main
SOURCES = $(wildcard *.tex) $(wildcard chapters/*.tex) $(wildcard sections/*.tex)
BIBFILES = $(wildcard *.bib)
IMAGES = $(wildcard iamges/*.png) $(wildcard iamges/*.jpg)

.PHONY: all del_target clean

PDF = $(MAIN).pdf

# 默认目标
all: $(PDF)
# all: del_target $(PDF)

$(PDF): $(SOURCES) $(BIBFILES) $(IMAGES)| $(BUILDDIR)
	$(TEX) $(TEXFLAGS) -output-directory=$(BUILDDIR) $(MAIN).tex
	
	echo compile the bib file
	$(BIB) $(BUILDDIR)\$(MAIN)

	echo second compile
	$(TEX) $(TEXFLAGS) -output-directory=$(BUILDDIR) $(MAIN).tex

	echo third compile
	$(TEX) $(TEXFLAGS) -output-directory=$(BUILDDIR) $(MAIN).tex
	copy "$(BUILDDIR)\$(MAIN).pdf" "." > nul
    
# 创建 build 目录
$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# 快速编译（不处理参考文献）
fast: $(SOURCES) | $(BUILDDIR)
	$(TEX) $(TEXFLAGS) -output-directory=$(BUILDDIR) $(MAIN)
	cp $(BUILDDIR)/$(MAIN).pdf .

# 使用 latexmk
latexmk:
	latexmk -pdf -outdir=$(BUILDDIR) $(MAIN)
	cp $(BUILDDIR)/$(MAIN).pdf .

del_target:
	del $(MAIN).pdf

clean: del_target
	cd $(BUILDDIR) && del /s /q *.xml *.bcf *.log *.aux *.synctex.gz *.hd *.idx *.out *.toc *.bbl *.blg *.lof *.lot
	del /s /q main.pdf
	cd ..