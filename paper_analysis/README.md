# 试卷分析

## 文件说明
### 主文件
* default_yixf.latex：ita.Rmd使用的LaTeX模板
* fix_linkcolor.tex：修改LaTeX模板中链接的颜色，同样由ita.Rmd调用
* ita.Rmd：主文件，R Markdown文件，调用itemTestAnalysis.R进行试卷分析
* itemTestAnalysis.R：进行试卷分析的R脚本,输入数据包括两部分：test_a1.csv和test_info.txt
* test_a1.csv：试卷分析时读入的答卷数据，可以由test_a1.xls导出
* test_a1.xls：手工整理的答卷数据
* test_info.txt：试卷的基本信息

### 输出文件
* ita_files/*：试卷分析过程中生成的图片
* tables/*：试卷分析过程中生成的表格
* ita.pdf：最终的试卷分析报告
* ita.tex：TeX格式的试卷分析报告

## 文件关系
1. ita.Rmd依赖于：

* default_yixf.latex
* fix_linkcolor.tex
* itemTestAnalysis.R

2. itemTestAnalysis.R依赖于：

* test_info.txt
* test_a1.csv

3. test_a1.csv来源于：

* test_a1.xls
