@echo off
echo 正在清理 LaTeX 临时文件...
del /s /q *.aux *.log *.synctex.gz *.fls *.fdb_latexmk *.out
del /s /q *.toc *.lof *.lot *.bbl *.blg *.nav *.snm *.vrb
echo 清理完成！
pause