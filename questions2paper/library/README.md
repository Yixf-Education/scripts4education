## 文件夹及文件说明
* 此library文件夹下是试题库
* 文件命名格式，示例如下
```
a_jianda_1_1.tex
```

## 文件命名格式说明
* 文件使用tex作为后缀
* 除后缀外文件名由以下划线分隔的四部分构成
	* 第一部分是AB卷标识，可用选项【其实没有限制……】
```
[a,b]
```
	* 第二部分是题型标识，可用选项
```
# 单选题，多选题，填空题，判断题，简答题，论述题，计算题，编程题，应用题，名词解释，其他
[danxuan,duoxuan,tiankong,panduan,jianda,lunshu,jisuan,biancheng,yingyong,mingci,qita]
```
	* 第三部分是章节标识，可用选项
```
[1,2,3,4,5,6,7,8,9,...]
```
	* 第四部分是章节内的题目编号标识，可用选项
```
[1,2,3,4,5,6,7,8,9,...]
```

## 友情提示
可以在每个文件的第一行用``%``注明该题目考查的知识点，便于收集试卷信息。举例如下
```tex
% Linux的历史
%% Linux的发行版
%%% Linux的文件系统
```
