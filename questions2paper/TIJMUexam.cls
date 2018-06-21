%%
%% This is file `TIJMUexam.cls',
%% modified from BHCexam(v0.3,2014/02/18).
%%
%% \CharacterTable
%%  {Upper-case    \A\B\C\D\E\F\G\H\I\J\K\L\M\N\O\P\Q\R\S\T\U\V\W\X\Y\Z
%%   Lower-case    \a\b\c\d\e\f\g\h\i\j\k\l\m\n\o\p\q\r\s\t\u\v\w\x\y\z
%%   Digits        \0\1\2\3\4\5\6\7\8\9
%%   Exclamation   \!     Double quote  \"     Hash (number) \#
%%   Dollar        \$     Percent       \%     Ampersand     \&
%%   Acute accent  \'     Left paren    \(     Right paren   \)
%%   Asterisk      \*     Plus          \+     Comma         \,
%%   Minus         \-     Point         \.     Solidus       \/
%%   Colon         \:     Semicolon     \;     Less than     \<
%%   Equals        \=     Greater than  \>     Question mark \?
%%   Commercial at \@     Left bracket  \[     Backslash     \\
%%   Right bracket \]     Circumflex    \^     Underscore    \_
%%   Grave accent  \`     Left brace    \{     Vertical bar  \|
%%   Right brace   \}     Tilde         \~}
%%

\NeedsTeXFormat{LaTeX2e}[1995/12/01]
\ProvidesClass{TIJMUexam}
  [2014/09/24 v0.1 TIJMUexam
   document class]

% 试卷选项
\newif\if@sixteenkpaper \@sixteenkpaperfalse
\DeclareOption{16kpaper}{\@sixteenkpapertrue}
\newif\if@marginline \@marginlinefalse
\DeclareOption{marginline}{\@marginlinetrue}
\newif\if@noindent \@noindentfalse
\DeclareOption{noindent}{\@noindenttrue}
\DeclareOption{answers}{\PassOptionsToClass{\CurrentOption}{exam}}
\newif\if@printbox \@printboxfalse
\DeclareOption{printbox}{\@printboxtrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{exam}}
\ProcessOptions
\LoadClass[addpoints]{exam}

\RequirePackage[UTF8,heading=true,fontset=none]{ctex}
\ctexset{fontset=adobe,space=auto}
\RequirePackage{ifpdf,ifxetex}
\RequirePackage{amsmath,amssymb,amsthm,bm,bbding,pifont,dsfont}
\RequirePackage{mathtools}
\RequirePackage{paralist,cases,tabularx}
\RequirePackage{pstricks,pst-plot,xcolor,graphicx}
\newcolumntype{Y}{>{\centering\arraybackslash}X}
%\RequirePackage{mdframed}
\RequirePackage{framed}

\RequirePackage{listings}
\lstset{
  language=Perl,
  basicstyle=\normalsize\tt,
  %basicstyle=\small\tt,
  %frame=l,
  %numbers=left,
  %numberstyle=\footnotesize,
  showstringspaces=false,
  %breaklines=false,
  %breakatwhitespace=false,
  breaklines=true,
  breakatwhitespace=true,
}

% 试卷页面
\if@marginline
  \marginparwidth = 2cm
  \if@sixteenkpaper
    %\RequirePackage[papersize={184mm,260mm},hmargin={3cm,2cm},
    %vmargin={2cm,2cm},marginparsep=0.5cm,hoffset=0cm,voffset=0cm,
    %footnotesep=0.5cm,headsep=0.5cm,twoside]{geometry}
    \RequirePackage[papersize={184mm,260mm},hmargin={3cm,2cm},
    vmargin={2cm,2cm},marginparsep=0.5cm,hoffset=0cm,voffset=0cm,
    footnotesep=0.5cm,headsep=0.5cm]{geometry}
  \else
    %\RequirePackage[paper=a4paper,hmargin={3cm,2cm},vmargin={2cm,2cm},
    %marginparsep=0.5cm,hoffset=0cm,voffset=0cm,footnotesep=0.5cm,
    %headsep=0.5cm,twoside]{geometry}
    \RequirePackage[paper=a4paper,hmargin={1.5cm,0.5cm},vmargin={1cm,1cm},
    marginparsep=0.2cm,hoffset=0cm,voffset=0.4cm,footnotesep=0cm,footskip=0.2cm,
    headsep=0cm]{geometry}
  \fi
\else
  \if@sixteenkpaper
    \RequirePackage[papersize={184mm,260mm},hmargin={2cm,2cm},
    vmargin={2cm,2cm},marginparsep=0.5cm,hoffset=0cm,voffset=0cm,
    footnotesep=0.5cm,headsep=0.5cm]{geometry}
  \else
    \RequirePackage[papersize={210mm,297mm},hmargin={2cm,2cm},vmargin={2cm,2cm},
    marginparsep=0.5cm,hoffset=0cm,voffset=0cm,footnotesep=0.5cm,
    headsep=0.5cm]{geometry}
  \fi
\fi

%\renewcommand{\baselinestretch}{1.5}
\renewcommand{\baselinestretch}{1.2}
% 试卷页眉页脚
\pagestyle{headandfoot}
\firstpageheader{}{}{}
%\runningheader{}{\oddeven{\kaoshengxinxi}{}}{}
\runningheader{}{\kaoshengxinxi}{}{}
\footer{}{\small 第 \thepage 页（共 \numpages 页）}{}

%\RequirePackage{fancyhdr}
%\RequirePackage{fancybox}
%\pagestyle{fancy}
%\fancyhead[CO]{\kaoshengxinxi}
%%\fancyfoot[C]{\small \textit{\@kemu（\textnormal{\@abjuan} 卷）}\quad 第 \thepage 页（共 \numpages 页）}
%\fancyfoot[C]{\small 第 \thepage 页（共 \numpages 页）}
%\renewcommand{\headrulewidth}{0pt}
%\renewcommand{\headsep}{5pt}
%\renewcommand{\footskip}{15pt}
%\fancypage{
%\setlength{\fboxsep}{8pt}
%\setlength{\fboxrule}{0.8pt}
%\setlength{\shadowsize}{0pt}
%\shadowbox
%}{}
%\fancypagestyle{firststyle}{\fancyhf{}}

\pointname{分}
\pointformat{\kaishu (\thepoints)}
\renewcommand{\questionshook}{
  \settowidth{\leftmargin}{22.\hskip\labelsep}
  \if@noindent \setlength\leftmargin{0pt} \fi
}
\renewcommand{\thepartno}{\arabic{partno}}
\renewcommand{\partlabel}{(\thepartno)}
\renewcommand{\partshook}{
  \settowidth{\leftmargin}{(3).\hskip\labelsep}
  \if@noindent \setlength\leftmargin{0pt} \fi
}
% 试题答案
\newif\if@cancelspace \@cancelspacetrue
\renewcommand{\solutiontitle}{\noindent \heiti 参考答案： \songti \noindent}
\renewenvironment{solution}
  {
    \ifprintanswers
      \begingroup
      \Solution@Emphasis
      \begin{TheSolution}
    \else
      \if@cancelspace
        %\unskip
      \else
        \par
        \penalty 0
        %\vspace*{5cm}
        %\vfill
%        \begin{minipage}[c][0.4\textheight][s]{0.95\textwidth}
%        \vfill
%        \if@printbox \if@houpingfen \houpingfen \fi \fi
%        \end{minipage}
        \vfill
        \if@printbox \if@houpingfen \houpingfen \fi \fi
      \fi
      \setbox\z@\vbox\bgroup
    \fi
  }{
    \ifprintanswers
      \end{TheSolution}
      \endgroup
    \else
      \egroup
    \fi
  }
% 装订线
\if@marginline
  \newsavebox{\zdx}
  \sbox{\zdx}{
    \begin{minipage}{0.85\paperheight}
    \begin{center}
%      \heiti 班级\underline{\hspace{15ex}} \quad
%      姓名 \underline{\hspace{15ex}} \quad
%      学号 \underline{\hspace{15ex}} \quad \\
    \vspace{5ex}
    \dotfill 装 \dotfill 订 \dotfill 线 \dotfill
    \end{center}
    \end{minipage}
  }
  \newsavebox{\zdxl}
  \sbox{\zdxl}{
    \begin{minipage}{0.85\paperheight}
    \begin{center}
%      \heiti 班级\underline{\hspace{15ex}} \quad
%      姓名 \underline{\hspace{15ex}} \quad
%      学号 \underline{\hspace{15ex}} \quad \\
    \vspace{5ex}
    \dotfill 装 \dotfill 订 \dotfill 线 \dotfill
    \end{center}
    \end{minipage}
  }
  \newsavebox{\zdxr}
  \sbox{\zdxr}{
    \begin{minipage}{0.85\paperheight}
    \begin{center}
%      \heiti \hfill 请 \hfill 不 \hfill 要 \hfill 在 \hfill
%      装 \hfill 订 \hfill 线 \hfill 内 \hfill 答 \hfill 题 \hfill \\
    \vspace{5ex}
    %\dotfill 装 \dotfill 订 \dotfill 线 \dotfill
    \heiti \hfill 请 \hfill 不 \hfill 要 \hfill 在 \hfill
    装 \hfill 订 \hfill 线 \hfill 内 \hfill 答 \hfill 题 \hfill \\
    \end{center}
    \end{minipage}
  }
  \newcommand{\printml}{
    \marginpar{\rotatebox{90}{\usebox{\zdx}}}
  }
  \newcommand{\printmlol}{
    \marginpar{\rotatebox{90}{\usebox{\zdxl}}}
  }
  \newcommand{\printmlor}{
    \marginpar{\rotatebox{-90}{\usebox{\zdxr}}}
  }
  \reversemarginpar
\fi

%\RequirePackage{mparhack}
%\RequirePackage[strict]{changepage}
%\if@marginline
%  \newsavebox{\zdx}
%  \sbox{\zdx}{
%    \begin{minipage}{0.8\paperheight}
%      \begin{center}
%        {\bf \hrulefill \rotatebox{-90}{线} \qquad \rotatebox{-90}{订} \qquad \rotatebox{-90}{装} \hrulefill}
%      \end{center}
%    \end{minipage}
%}
%  \newcommand{\printml}{
%	\makeatletter
%	\checkoddpage
%	\ifoddpage
%      \marginpar{\rotatebox{90}{\usebox{\zdx}}}
%	\fi
%	\makeatother
%  }
%  \reversemarginpar
%\fi


% 试卷头
%\newcommand\biaoti[1]{\def\@biaoti{#1}}
%\newcommand\fubiaoti[1]{\def\@fubiaoti{#1}}
%\newcommand\xinxi{专业：\underline{\hspace{15ex}} \  班级：\underline{\hspace{12.5ex}} \  姓名：\underline{\hspace{12ex}} \  学号：\underline{\hspace{13ex}}}
%\renewcommand\maketitle{
%  \begin{center}{\heiti \Large{\@biaoti}}\end{center}
%  \begin{center}{\heiti \Large{\@fubiaoti}}\end{center}
%}
%\newcommand\xinxi[2]{
%  \def\@zongfen{#1}
%  \def\@shijian{#2}
%}
\RequirePackage{setspace}
\newcommand\xuexiao[1]{\def\@xuexiao{#1}}
\newcommand\yearb[1]{\def\@yearb{#1}}
\newcommand\yeare[1]{\def\@yeare{#1}}
\newcommand\xueqi[1]{\def\@xueqi{#1}}
\newcommand\zhuanye[1]{\def\@zhuanye{#1}}
\newcommand\kecheng[1]{\def\@kecheng{#1}}
\newcommand\abjuan[1]{\def\@abjuan{#1}}
\newcommand\kaibijuan[1]{\def\@kaibijuan{#1}}
\newcommand{\biaoti}[1]{\begin{spacing}{1.5}\begin{center}\Large \textbf{#1} \end{center}\end{spacing}}
\renewcommand{\maketitle}{
%缩小添加密封线后试卷头部的大空白
  \vspace{-1cm}
  \biaoti{\@xuexiao \@yearb \ -- \@yeare 学年 \@xueqi \ 学期\\
  \underline{\@zhuanye} 专业 \underline{\@kecheng} 课程考试试卷(\@abjuan)  (\@kaibijuan)}
  \bigskip
  \kaoshengxinxi
%  \thispagestyle{firststyle}
}
%\newcommand\kaoshengxinxi{\indent 专业：\underline{\hspace{15ex}} \  班级：\underline{\hspace{14ex}} \  姓名：\underline{\hspace{14ex}} \  学号：\underline{\hspace{15ex}} \vspace*{-0.4cm}}
\newcommand\kaoshengxinxi{\qquad \qquad 专业：\underline{\hspace{15ex}} \  班级：\underline{\hspace{14ex}} \  姓名：\underline{\hspace{14ex}} \  学号：\underline{\hspace{15ex}} }

\newcommand\mininotice{
  \bigskip
  \begin{center}{
    \kaishu （本试卷满分 \@zongfen 分，考试时间 \@shijian 分钟）}
  \end{center}
}
\newcommand{\notice}{
  \vspace*{0.5cm}
  \begin{flushleft}
  \heiti 注意事项： \songti
  \begin{enumerate}
  \item 答卷前，考生务必将专业、班级、姓名、学号等填写清楚。
  \item 本试卷共 \numquestions{} 道试题，满分 \@zongfen 分，考试时间 \@shijian 分钟。
  \end{enumerate}
  \end{flushleft}
}

% 试卷头部的评分框
\newlength\@boxwidth
\setlength\@boxwidth{0ex}
\newcommand\defen{
  %\bigskip
  \qquad \qquad
  \hspace{-0.5cm}
  \begin{minipage}{\@boxwidth}
  \heiti
  %\begin{tabularx}{13cm}{@{\extracolsep{\fill}}|c|c|c|c|c|c|c|c|c|c|c|c|X|}
  \begin{tabularx}{14.6cm}{|p{0.8cm}|X|X|X|X|X|X|X|X|X|X|p{0.9cm}|p{1.9cm}|}
  \hline
  题号 & 一 & 二 & 三 & 四 & 五 & 六 & 七 & 八 & 九 & 十 & 总\ 分 & 核查人签字\\
  \hline
  得分 &  &  &  &  &  &  &  &  &  &  &  & \\
  \hline
  \end{tabularx}
  \end{minipage}
  \bigskip
}
% 每个大题前的评分框
\if@printbox \setlength\@boxwidth{18ex} \fi
\newcommand\pingfen{
  \heiti
  \begin{minipage}{\@boxwidth}
  \begin{tabular}{|c|c|}
  \hline
  得分 & 评阅人\\
  \hline
      &       \\
  \hline
  \end{tabular}
  \end{minipage}
}
% 每个小题后的评分框
\newcommand{\houpingfen}{
  \hfill
  \begin{tabular}{|l|l|}
    \hline
    得分 & \hspace*{1.5cm}\\
    \hline
  \end{tabular}
  \bigskip
}

% 大题设置：单选题，多选题，填空题，判断题，简答题，论述题，计算题，编程题，应用题，名词解释，其他
\newcounter{@dati}
\newif\if@houpingfen \@houpingfenfalse

% 单选题
\newcommand\setdanx[3]{
  \def\@danxuan@zongfen{#1}
  \def\@danxuan@tishu{#2}
  \def\@danxuan@fen{#3}
}
\newcommand\danxuan{
  \@houpingfenfalse
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、单选题（本大题共 \@danxuan@tishu 题，每题 \@danxuan@fen 分，满分 \@danxuan@zongfen 分）
    \end{minipage}
  }
}

% 多选题
\newcommand\setduox[3]{
  \def\@duoxuan@zongfen{#1}
  \def\@duoxuan@tishu{#2}
  \def\@duoxuan@fen{#3}
}
\newcommand\duoxuan{
  \@houpingfenfalse
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、多选题（本大题共 \@duoxuan@tishu 题，每题 \@duoxuan@fen 分，满分 \@duoxuan@zongfen 分）
    \end{minipage}
  }
}
\newcommand{\onech}[4]{
\renewcommand\arraystretch{1.4}
\begin{tabularx}{\linewidth}{XXXX}
\setlength\tabcolsep{0pt}
(A) #1 & (B) #2 & (C) #3 & (D) #4 \\
\end{tabularx}
\unskip \unskip}
\newcommand{\twoch}[4]{
\renewcommand\arraystretch{1.4}
\begin{tabularx}{\linewidth}{XX}
\setlength\tabcolsep{0pt}
(A) #1 & (B) #2 \\
(C) #3 & (D) #4
\end{tabularx}
\unskip \unskip}
\newcommand{\fourch}[4]{
\renewcommand\arraystretch{1.4}
\begin{tabularx}{\linewidth}{X}
\setlength\tabcolsep{0pt}
(A) #1 \\
(B) #2 \\
(C) #3 \\
(D) #4 \\
\end{tabularx}
\unskip \unskip}

% 填空题
\newcommand\settk[3]{
  \def\@tiankong@zongfen{#1}
  \def\@tiankong@tishu{#2}
  \def\@tiankong@fen{#3}
}
\newcommand\tiankong{
  \@houpingfenfalse
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
    \heiti \chinese{@dati}、填空题（本大题共 \@tiankong@tishu 题，每题\@tiankong@fen 分，满分 \@tiankong@zongfen 分）
    \end{minipage}
  }
}
\newcommand{\stk}[1]{
  \ifprintanswers
    \underline{~#1~}
  \else
    \underline{~\hspace{1cm}~}
  \fi}
\newcommand{\mtk}[1]{
  \ifprintanswers
    \underline{~#1~}
  \else
    \underline{~\hspace{2cm}~}
  \fi}
\newcommand{\ltk}[1]{
  \ifprintanswers
    \underline{~#1~}
  \else
    \underline{~\hspace{3cm}~}
  \fi}

% 判断题
\newcommand\setpd[3]{
  \def\@panduan@zongfen{#1}
  \def\@panduan@tishu{#2}
  \def\@panduan@fen{#3}
}
\newcommand\panduan{
  \@houpingfenfalse
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
    \heiti \chinese{@dati}、判断题（本大题共 \@panduan@tishu 题，每题\@panduan@fen 分，满分 \@panduan@zongfen 分）
    \end{minipage}
  }
}

% 简答题
\newcommand\setjd[3]{
  \def\@jianda@zongfen{#1}
  \def\@jianda@tishu{#2}
  \def\@jianda@fen{#3}
}
\newcommand\jianda{
  \@cancelspacefalse
  \@houpingfentrue
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、简答题（本大题共 \@jianda@tishu 题，每题 \@jianda@fen 分，满分 \@jianda@zongfen 分）
    \end{minipage}
  }
}

% 论述题
\newcommand\setls[3]{
  \def\@lunshu@zongfen{#1}
  \def\@lunshu@tishu{#2}
  \def\@lunshu@fen{#3}
}
\newcommand\lunshu{
  \@cancelspacefalse
  \@houpingfentrue
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、论述题（本大题共 \@lunshu@tishu 题，每题 \@lunshu@fen 分，满分 \@lunshu@zongfen 分）
    \end{minipage}
  }
}

% 计算题
\newcommand\setjs[3]{
  \def\@jisuan@zongfen{#1}
  \def\@jisuan@tishu{#2}
  \def\@jisuan@fen{#3}
}
\newcommand\jisuan{
  \@cancelspacefalse
  \@houpingfentrue
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、计算题（本大题共 \@jisuan@tishu 题，每题 \@jisuan@fen 分，满分 \@jisuan@zongfen 分）
    \end{minipage}
  }
}

% 编程题
\newcommand\setbch[3]{
  \def\@biancheng@zongfen{#1}
  \def\@biancheng@tishu{#2}
  \def\@biancheng@fen{#3}
}
\newcommand\biancheng{
  \@cancelspacefalse
  \@houpingfentrue
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、编程题（本大题共 \@biancheng@tishu 题，每题 \@biancheng@fen 分，满分 \@biancheng@zongfen 分）
    \end{minipage}
  }
}

% 应用题
\newcommand\setyy[3]{
  \def\@yingyong@zongfen{#1}
  \def\@yingyong@tishu{#2}
  \def\@yingyong@fen{#3}
}
\newcommand\yingyong{
  \@cancelspacefalse
  \@houpingfentrue
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、应用题（本大题共 \@yingyong@tishu 题，每题 \@yingyong@fen 分，满分 \@yingyong@zongfen 分）
    \end{minipage}
  }
}

% 名词解释
\newcommand\setmc[3]{
  \def\@mingci@zongfen{#1}
  \def\@mingci@tishu{#2}
  \def\@mingci@fen{#3}
}
\newcommand\mingci{
  \@cancelspacefalse
  \@houpingfentrue
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、名词解释（本大题共 \@mingci@tishu 题，每题 \@mingci@fen 分，满分 \@mingci@zongfen 分）
    \end{minipage}
  }
}

% 其他
\newcommand\setqt[3]{
  \def\@qita@zongfen{#1}
  \def\@qita@tishu{#2}
  \def\@qita@fen{#3}
}
\newcommand\qita{
  \@cancelspacefalse
  \@houpingfentrue
  \stepcounter{@dati}
  \fullwidth{
    \if@printbox \pingfen \fi
    \begin{minipage}{\textwidth-\@boxwidth}
      \heiti \chinese{@dati}、其他（本大题共 \@qita@tishu 题，每题 \@qita@fen 分，满分 \@qita@zongfen 分）
    \end{minipage}
  }
}

\delimitershortfall-1sp
\newcommand\abs[1]{\left|#1\right|}
\renewcommand{\geq}{\geqslant}
\renewcommand{\ge}{\geqslant}
\renewcommand{\leq}{\leqslant}
\renewcommand{\le}{\leqslant}

\AtEndOfPackage{\makeatletter\input{TIJMUexam.cfg}\makeatother}

\endinput

%%
%% End of file `TIJMUexam.cls'.
