# 随机抽题与试卷排版

## 说明
* 从library中随机抽题并进行排版
* 试卷排版格式：天津医科大学

## 文件
* library/*：题库文件夹
* snippets/*：生成试卷过程中的TeX文件，以大题类型进行组织
* gpra.pl：随机抽题、自动生成试卷的脚本
* paper.conf：使用脚本生成试卷的配置文件
* paper.sh：一键随机抽题、排版试卷
* paper.tex：Perl脚本自动生成的TeX文件
* paper_a.pdf：最终的试卷，PDF格式
* paper_a.tex：最终的试卷，TeX格式
* paper_a_answers.pdf：附有标准答案的最终试卷，PDF格式
* paper_a_answers.tex：附有标准答案的最终试卷，TeX格式
* TIJMUexam.cfg：由Perl脚本自动生成
* TIJMUexam.cls：试卷模板的相关设置

## 使用
### 使用shell脚本
```bash
./paper.sh
```

### 手动由tex生成pdf
```bash
# 使用latexmk
latexmk -pdf -xelatex a_paper.tex
# 使用xelatex，可能需要运行不止一次
xelatex a_paper.tex
```

