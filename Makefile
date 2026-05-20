# Makefile for LaTeX project
TEX = xelatex
BIB = biber
TEXFLAGS = -synctex=1 -interaction=nonstopmode
OUTPUTDIR = output
BUILDDIR = build
MAIN = main
SOURCES = $(wildcard *.tex) $(wildcard chapters/*.tex) $(wildcard sections/*.tex)
BIBFILES = $(wildcard *.bib)
# IMAGES = $(wildcard figure/*.png figure/*.jpg figure/*.pdf)
CHAPTERS = $(wildcard chapter/*.tex)
CLS_FILE = scut_thesis/scutthesis.cls
COVER_FILE = cover_file/thesis_cover.pdf
BIB_FILE = biblibrary/refrence.bib
MATLAB_PDF = $(wildcard matlab/ground_effect/pdf/thrust/*.pdf matlab/ground_effect/pdf/moment/*.pdf matlab/ground_effect/pdf/anti_ge_moment/*.pdf matlab/ground_effect/pdf/anti_ge_thrust/*.pdf)

.PHONY: all del_target clean

PDF = $(MAIN).pdf

# 默认目标
all: $(PDF)
# all: del_target $(PDF)


$(PDF): $(SOURCES) $(BIBFILES) $(IMAGES) $(CHAPTERS) $(MATLAB_PDF) $(CLS_FILE) $(COVER_FILE) $(BIB_FILE)
	$(TEX) $(TEXFLAGS) $(MAIN).tex
	
	echo compile the bib file
	$(BIB) $(MAIN)

	echo second compile
	$(TEX) $(TEXFLAGS) $(MAIN).tex

	echo third compile
	$(TEX) $(TEXFLAGS) $(MAIN).TEX

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
	del /s /q *.xml *.bcf *.log *.aux *.synctex.gz *.hd *.idx *.out *.toc *.bbl *.blg *.lof *.lot
	del /s /q main.pdf
	cd ..