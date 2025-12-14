# Makefile for LaTeX project
TEX = pdflatex
BIB = bibtex
TEXFLAGS = -synctex=1 -interaction=nonstopmode -file-line-error
OUTPUTDIR = output
BUILDDIR = build
MAIN = main
SOURCES = $(wildcard *.tex) $(wildcard chapters/*.tex) $(wildcard sections/*.tex)
BIBFILES = $(wildcard *.bib)

.PHONY: all clean cleanall view help

# 默认目标
all: $(BUILDDIR)/$(MAIN).pdf

# 主规则：构建 PDF
$(BUILDDIR)/$(MAIN).pdf: $(SOURCES) $(BIBFILES) | $(BUILDDIR)
	@echo "=== first compile ==="
	$(TEX) $(TEXFLAGS) -output-directory=$(BUILDDIR) $(MAIN)
	
	@echo "=== 运行 BibTeX（如果需要）==="
	@if [ -f "$(BUILDDIR)/$(MAIN).aux" ]; then \
		cd $(BUILDDIR) && $(BIB) $(MAIN); \
	fi
	
	@echo "=== 第二次编译 ==="
	$(TEX) $(TEXFLAGS) -output-directory=$(BUILDDIR) $(MAIN)
	
	@echo "=== 第三次编译 ==="
	$(TEX) $(TEXFLAGS) -output-directory=$(BUILDDIR) $(MAIN)
	
	@echo "=== 复制 PDF 到根目录 ==="
	cp $(BUILDDIR)/$(MAIN).pdf .

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

# 清理临时文件
clean:
	rm -f *.aux *.log *.synctex.gz *.fls *.fdb_latexmk *.out
	rm -f *.toc *.lof *.lot *.bbl *.blg *.nav *.snm *.vrb
	rm -f *.run.xml *.bcf

# 完全清理（包括 build 目录和 PDF）
cleanall: clean
	rm -rf $(BUILDDIR)
	rm -f $(MAIN).pdf

# 查看 PDF
view:
ifeq ($(OS),Windows_NT)
	start $(MAIN).pdf
else
	open $(MAIN).pdf  # macOS
	# xdg-open $(MAIN).pdf  # Linux
endif

# 帮助信息
help:
	@echo "可用命令:"
	@echo "  make all     - 完整编译（默认）"
	@echo "  make fast    - 快速编译（跳过 BibTeX）"
	@echo "  make latexmk - 使用 latexmk 编译"
	@echo "  make clean   - 清理临时文件"
	@echo "  make cleanall- 完全清理（包括 PDF）"
	@echo "  make view    - 打开 PDF 文件"
	@echo "  make help    - 显示此帮助信息"