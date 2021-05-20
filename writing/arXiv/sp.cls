% Semantics & Pragmatics style file.
% Kai von Fintel, Christopher Potts, and Chung-chieh Shan

\NeedsTeXFormat{LaTeX2e}[1994/06/01]
\ProvidesClass{sp}[2015/01/04 v.3.0 Class for Semantics & Pragmatics]

%====================================================================
%===================== release notes ================================

% 2015-01-02: v3.0, include expex option and footnote exx formatting

%======================= Outlinen ====================================
%====================================================================

% OUTLINE OF THIS CLASS FILE
%   option declarations
%   required packages
%   metadata
%   page dimensions
%   title
%   running headers
%   frontmatter
%   sectioning
%   footnotes
%   bibliography
%   backmatter
%   other environments
%   useful macros

%=====================================================================
%======================== option declarations ========================

% font selection
\newcount\@fontenum
% example-numbering packages
\newif\if@expex
\newif\if@linguex
% production settings
\newif\if@biblatex
\newif\if@final

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

\newcommand{\@sizeoption@err}{\ClassError{sp}
  {Cannot use size option \CurrentOption}
  {The S&P style requires (and automatically loads) 12pt text}}

\DeclareOption{10pt}{\@sizeoption@err}
\DeclareOption{11pt}{\@sizeoption@err}

% mutually exclusive font selection
\DeclareOption{cm}{\@fontenum=0}
\DeclareOption{times}{\@fontenum=1}
\DeclareOption{lucida}{\@fontenum=2}
\DeclareOption{lucidaot}{\@fontenum=3}
% example-numbering packages
\DeclareOption{expex}{\@expextrue}
\DeclareOption{linguex}{\@linguextrue}
% production settings
\DeclareOption{biblatex}{\@biblatextrue}
\DeclareOption{final}{\@finaltrue}

\ExecuteOptions{times} % times is the default.
\ProcessOptions\relax
\LoadClass[12pt,twoside]{article}

% amsmath must be loaded before unicode-math; might as well load it here
\RequirePackage[leqno,tbtags]{amsmath}

\RequirePackage{ifxetex}
% if 1) lucida is requested, and 2) lucimatx can't be found, and 3) we're using XeTeX,
% fall back to lucidaot with a warning
\ifnum \@fontenum = 2
  \IfFileExists{lucimatx.sty}{}{
    \ifxetex
      \ClassWarning{sp.cls}{Lucida requested but cannot find font; trying LucidaOT}
      \@fontenum=3
    \fi
  }
\fi

% Load fonts as indicated by \@fontenum setting.
\ifcase \@fontenum % 0 = cm
  % Computer Modern is the standard font; do nothing
\or % 1 = times
  \RequirePackage[T1]{fontenc}
  \RequirePackage{mathptmx}
\or % 2 = lucida
  \RequirePackage[romanfamily=bright-osf,scale=0.9,stdmathdigits=true]{lucimatx}
  \let\llbracket\ldbrack
  \let\rrbracket\rdbrack
  \DeclareTextCommand{\textbullet}{\encodingdefault}{\UseTextSymbol{OMS}\textbullet} % the default is tiny
  \DeclareMathSymbol{\nLeftrightarrow}{\mathrel}{arrows}{105} % the default, 103, is too short
\or % 3 = lucidaot
  \RequirePackage{fontspec}
  \RequirePackage{unicode-math}
  \defaultfontfeatures{Ligatures=TeX,Scale=0.9}
  % load Lucida font files from local directory if possible
  \IfFileExists{./fonts/LucidaBrightOT.otf}{
    \ClassInfo{sp.cls}{Loading LucidaOT files from local directory (./fonts/)}
    \defaultfontfeatures+{Path=./fonts/,Extension=.otf}
    % pre-configure the fonts for loading via their canonical / system name
    % by specifying the filenames for each Upright/Bold/Italic/BoldItalic variant
    \defaultfontfeatures[Lucida Bright OT]{
      UprightFont=LucidaBrightOT,
      BoldFont=LucidaBrightOT-Demi,
      ItalicFont=LucidaBrightOT-Italic,
      BoldItalicFont=LucidaBrightOT-DemiItalic}
    \defaultfontfeatures[Lucida Sans OT]{
      UprightFont=LucidaSansOT,
      BoldFont=LucidaSansOT-Demi,
      ItalicFont=LucidaSansOT-Italic,
      BoldItalicFont=LucidaSansOT-DemiItalic}
    \defaultfontfeatures[Lucida Sans Typewriter OT]{
      UprightFont=LucidaSansTypewriterOT-Bold,
      BoldFont=LucidaSansTypewriterOT-Bold,
      ItalicFont=LucidaSansTypewriterOT-Oblique,
      BoldItalicFont=LucidaSansTypewriterOT-BoldOblique}
    % there is no such pre-configuration implemented in unicode-math,
    % so \setmathfont must be called distinctly in each branch
    \setmathfont{LucidaBrightMathOT}
    \setmathfont{LucidaBrightMathOT-Demi}[version=bold]
  }{
    \ClassInfo{sp.cls}{Loading LucidaOT fonts from system}
    \setmathfont{Lucida Bright Math OT}
  }
  % load fonts using their canonical / system names
  \setmainfont{Lucida Bright OT}[Numbers=OldStyle]
  \setsansfont{Lucida Sans OT}
  \setmonofont{Lucida Sans Typewriter OT}
  % shim several math commands to approximate definitions in lucimatx.sty
  \def\llbracket{\symbol{"27E6}} % MATHEMATICAL LEFT WHITE SQUARE BRACKET
  \def\rrbracket{\symbol{"27E7}} % MATHEMATICAL RIGHT WHITE SQUARE BRACKET
  \def\leadsto{\symbol{"21DD}} % RIGHTWARDS SQUIGGLE ARROW
  \def\Join{\symbol{"22C8}} % BOWTIE
  \def\Box{\symbol{"25A1}} % WHITE SQUARE
  \def\Diamond{\symbol{"25C7}} % WHITE DIAMOND
  \def\ulcorner{\symbol{"23A1}} % LEFT SQUARE BRACKET UPPER CORNER
  \def\urcorner{\symbol{"23A4}} % RIGHT SQUARE BRACKET UPPER CORNER
\fi
\ifnum \@fontenum < 2
  % load shims for non-Lucida fonts (0 = cm and 1 = times)
  \IfFileExists{stmaryrd.sty}{\RequirePackage{stmaryrd}}{
    \ClassWarning{sp.cls}{stmaryrd required but not available; double brackets may be rendered incorrectly}
    \newcommand{\llbracket}{\ensuremath{\left [\!\left [}}
    \newcommand{\rrbracket}{\ensuremath{\right ]\!\right ]}}
  }
  \RequirePackage{textcomp}
  \RequirePackage{amssymb}
\else
  % load extras for Lucida fonts (2 = lucida and 3 = lucidaot)
  \linespread{1.05}
\fi

% Strong widow and orphan control

\clubpenalty10000
\widowpenalty10000

% French Spacing

\frenchspacing

%=====================================================================
%========================= required packages =========================

\ifxetex
\else
  \RequirePackage[utf8]{inputenc}
  % define U+2011 NON-BREAKING HYPHEN as a regular hyphen + line break prohibition
  % Based on http://tex.stackexchange.com/a/23146
  % plain \mbox{-} doesn't allow the suffix to hyphenate automatically
  \DeclareUnicodeCharacter{2011}{\mbox{-}\nobreak\hskip\z@}
\fi
\RequirePackage{xspace}
% microtype handles punctuation at the right margin. We want it for
% the final product, but it's okay if authors lack it.
\IfFileExists{microtype.sty}{%
  \RequirePackage[final,protrusion={true,compatibility}]{microtype}
}{}
\RequirePackage[hyphens]{url}

% if [biblatex] is requested, check that biblatex-sp-unified is available;
% if the style cannot be found, fallback to BibTeX.
\if@biblatex
  \IfFileExists{biblatex-sp-unified.bbx}{}{
    \ClassWarning{sp.cls}{BibLaTeX requested but cannot find style; falling back to BibTeX}
    \@biblatexfalse
  }
\fi

\if@biblatex
  \RequirePackage[backend=biber,
                  bibstyle=biblatex-sp-unified,
                  citestyle=sp-authoryear-comp,
                  maxcitenames=3,
                  maxbibnames=99]{biblatex}
\else
  \RequirePackage{natbib}
  \bibpunct[: ]{(}{)}{,}{a}{}{,}
  \newcommand{\BIBand}{\&}
  \setlength{\bibsep}{0pt}
  \setlength{\bibhang}{0.25in}
  \bibliographystyle{sp}
  \newcommand{\posscitet}[1]{\citeauthor{#1}'s (\citeyear{#1})}
  \newcommand{\possciteauthor}[1]{\citeauthor{#1}'s}
  \newcommand{\pgposscitet}[2]{\citeauthor{#1}'s (\citeyear{#1}:~#2)}
  \newcommand{\secposscitet}[2]{\citeauthor{#1}'s (\citeyear{#1}:~$\S$#2)}
  \newcommand{\pgcitealt}[2]{\citealt{#1}:~#2}
  \newcommand{\seccitealt}[2]{\citealt{#1}:~$\S$#2}
  \newcommand{\pgcitep}[2]{(\citealt{#1}:~#2)}
  \newcommand{\seccitep}[2]{(\citealt{#1}:~$\S$#2)}
  \newcommand{\pgcitet}[2]{\citeauthor{#1} (\citeyear{#1}:~#2)}
  \newcommand{\seccitet}[2]{\citeauthor{#1} (\citeyear{#1}:~$\S$#2)}
  % \addbibresource{} and \printbibliography are the names of standard
  % BibLaTeX macros, which are shimmed here to call out to normal BibTeX.
  % The \@bibresources variable stores a list of bibliography arguments,
  % which are subsequently loaded by the 0-arity \printbibliography call.
  \def\@bibresources{}
  % \addbibresource mutably appends the given argument to \@bibresources,
  % maintaining \@bibresources as a comma-separated list of arguments.
  \newcommand{\addbibresource}[1]{%
    % \xdef is like \gdef, but immediately expands the second argument.
    \xdef\@bibresources{\@bibresources\ifx\@empty\@bibresources\else,\fi#1}}
  % \printbibliography simply calls the standard BibTeX \bibliography command
  % with the value of the \@bibresources variable (set earlier, as with BibLaTeX).
  \newcommand{\printbibliography}{\bibliography{\@bibresources}}
\fi

\RequirePackage[usenames,dvipsnames,table]{xcolor}
\definecolor{splinkcolor}{rgb}{.0,.2,.4}
\RequirePackage[colorlinks,breaklinks,
                linkcolor=splinkcolor,
                urlcolor=splinkcolor,
                citecolor=splinkcolor,
                filecolor=splinkcolor,
                plainpages=false,
                pdfpagelabels,
                bookmarks=false,
                pdfstartview=FitH]{hyperref}
\newcommand{\doi}[1]{\url{https://doi.org/#1}}
\urlstyle{rm}
\RequirePackage{graphicx}
\RequirePackage{float}
\RequirePackage[hang,FIGBOTCAP,loose]{subfigure}

%=====================================================================
%============================= metadata ==============================

\def\@pdfauthor{\relax}
\newcommand{\pdfauthor}[1]{\gdef\@pdfauthor{#1}}
\def\@pdftitle{\relax}
\newcommand{\pdftitle}[1]{\gdef\@pdftitle{#1}}
\def\@pdfkeywords{\relax}
\newcommand{\pdfkeywords}[1]{\gdef\@pdfkeywords{#1}}

\hypersetup{pdfauthor=\@pdfauthor,
            pdftitle=\@pdftitle,
            pdfkeywords=\@pdfkeywords}

\def\@spvolume{}
\newcommand{\spvolume}[1]{\gdef\@spvolume{#1}}

\def\@sparticle{}
\newcommand{\sparticle}[1]{\gdef\@sparticle{#1}}

\def\@spyear{}
\newcommand{\spyear}[1]{\gdef\@spyear{#1}}

\def\@spdoi{10.3765/sp.\@spvolume.\@sparticle}

\def\@splastpage{}
\newcommand{\splastpage}[1]{\gdef\@splastpage{#1}}

\def\@copyrightowner{\@shortauthor}
\newcommand{\copyrightowner}[1]{\gdef\@copyrightowner{#1}}

%=====================================================================
%========================== page dimensions ==========================

% Vertical.
\paperheight=11in
\topmargin=0in     %
\headheight=0.2in  % head: 1.5in (margin + head + sep = .5; latex adds 1in)
\headsep=0.3in     %
\topskip=0.1in     % included in the textheight
\textheight=8in    % text is 8in
\footskip=0.5in    % foot: 1.5in (.5 + 1.0in leftover)
\parskip=0pt

% Horizontal.
\paperwidth=8.5in
\textwidth=5.5in
\oddsidemargin=0.5in  % 1.5in due to LaTeX's calculations
\evensidemargin=0.5in % 1.5in due to LaTeX's calculations
\raggedbottom % constant spacing in the text; cost is a ragged bottom
\parindent=0.25in
\leftmargini=0.5in
\@ifundefined{mathindent}{}{\mathindent=0.5in\relax}%

% Tell dvips about our paper.
\special{papersize=8.5in,11in}

%=====================================================================
%============================== title ================================

% Formats individual <name--institute> pairs inside \author.
\newcommand{\spauthor}[1]{%
  \begin{minipage}[t]{16pc}\centering #1\end{minipage}\hspace{.5pc plus1pc}%
  \ignorespaces
}

\renewcommand*{\title}[2][]{\gdef\@shorttitle{#1}\gdef\@title{#2}}
\renewcommand*{\author}[2][]{\gdef\@shortauthor{#1}\gdef\@author{#2}}

% Adapted from JMLR.
\renewcommand{\maketitle}{%
  \par
  \begingroup
  \renewcommand{\thefootnote}{\fnsymbol{footnote}}
  \@maketitle\@thanks
  \setcounter{footnote}{0}
  \endgroup
  \let\maketitle\relax \let\@maketitle\relax
  \gdef\@thanks{}
  \let\thanks\relax%
}

% From salt.cls.
\newskip\onelineskip
\onelineskip=\baselineskip
\advance\onelineskip by0pt plus 4pt minus 2pt

\def\@maketitle{%
  \vbox{\hsize\textwidth%
    \linewidth\hsize%
    \centering
    \vskip\onelineskip
    \large\textbf{\@title}\@@par
    \normalsize
    \def\institute{\textit}%
    \newcommand{\AND}{\ignorespaces}%
    \let\par\@empty
    \@author
    \lineskiplimit\onelineskip
    \lineskip\onelineskip
    \@@par
  }%
  \global\everypar{\everypar{}\vskip 3.5ex}
}

%=====================================================================
%========================== running headers ==========================

% Prints publication and copyright info on the first page
\def\ps@spfirstheadings{
  \let\@mkboth\@gobbletwo
  \def\@oddhead{%
    \footnotesize
    \begin{minipage}[c]{.25in}
      \includegraphics[width=\textwidth]{sp-logo}
    \end{minipage}%
    \begin{minipage}[c]{5.25in}
      \href{http://semprag.org/}{Semantics \& Pragmatics}
        Volume \@spvolume,
        Article \@sparticle\ifx\@empty\@splastpage\else: 1--\@splastpage\fi,
        \@spyear\\
      \href{https://doi.org/\@spdoi}{https://doi.org/\@spdoi}
    \end{minipage}%
  }
  \def\@oddfoot{%
    \footnotesize
    \begin{minipage}[c]{\textwidth}
      \copyright \@spyear\ \@copyrightowner\\
      % Creative commons license text.
      This is an open-access article distributed under the terms of a
      Creative Commons Attribution License
      (\url{https://creativecommons.org/licenses/by/3.0/}).
    \end{minipage}%
  }
  \def\@evenhead{}
  \def\@evenfoot{}
}

% Prints abbreviated article information on non-initial pages.
\def\ps@spheadings{
  \let\@mkboth\@gobbletwo
  % short title on inner (left) side
  \def\@oddhead{\footnotesize\@shorttitle\hfill}
  % author name(s) on inner (right) side
  \def\@evenhead{\footnotesize\hfill\@shortauthor}
  % centered page number (with article prefix if available) on all pages
  \def\@oddfoot{\footnotesize\hfill\ifx\@empty\@sparticle\else\@sparticle:\fi\thepage\hfill}
  \let\@evenfoot\@oddfoot
}
% set spheadings as default pagestyle throughout document
\pagestyle{spheadings}

%=====================================================================
%=========================== final typeset ===========================


\if@final
  % load global variables into metadata
  \RequirePackage{sp-hyperxmp}
  \thispagestyle{spfirstheadings}
\else
  \thispagestyle{empty}
\fi


%=====================================================================
%=========================== frontmatter =============================

% The spacing specs (arg 2 of \list) are the same for the mshistory,
% abstract, and keywords environments, except that the abstract is
% indented somewhat.

% Single parameter determines the left and right margin size.
\newcommand{\frontmatterspacing}[1]{%
  \small
  \topsep 10\p@ \@plus4\p@   \@minus6\p@ % from size12.clo
  \advance\topsep by3.5ex plus -1ex minus -.2ex
  \setlength{\listparindent}{0em}
  \setlength{\itemindent}{0em}
  \setlength{\leftmargin}{#1}
  \setlength{\rightmargin}{\leftmargin}
  \setlength{\parskip}{0em}
}

\newenvironment{mshistory}%
{\list{}{\frontmatterspacing{0em}}%
\item\relax}%
{\endlist}

% \ignorespacesandpars inspired by http://tex.stackexchange.com/a/179034/3642
\def\ignorespacesandpars{%
  \@ifnextchar\par{\expandafter\ignorespacesandpars\@gobble}{\ignorespaces}}

\renewenvironment{abstract}%
{\list{}{\frontmatterspacing{0.25in}}%
\item\relax\textbf{\abstractname}~~\ignorespacesandpars}%
{\endlist}

\newenvironment{keywords}%
{\list{}{\frontmatterspacing{0em}}%
\item\relax\textbf{Keywords:}}%
{\endlist}

%=====================================================================
%============================ sectioning =============================

\renewcommand{\section}{\@startsection{section}{1}{\z@}%
  {-3.5ex plus -1ex minus -.2ex}%
  {1.8ex plus.2ex}%
  {\noindent\normalfont\bfseries}}

\renewcommand{\subsection}{\@startsection{subsection}{2}{\z@}%
  {-3.5ex plus -1ex minus -.2ex}%
  {1.8ex plus.2ex}%
  {\noindent\normalfont\bfseries}}

\renewcommand{\subsubsection}{\@startsection{subsubsection}{3}{\z@}%
  {-3.5ex plus -1ex minus -.2ex}%
  {1.8ex plus.2ex}%
  {\noindent\normalfont\bfseries}}

\renewcommand{\paragraph}{\@startsection{paragraph}{4}{\z@}%
  {3.5ex plus 1ex minus .2ex}%
  {-1em plus0.0ex}%
  {\noindent\normalsize\bfseries}}

\renewcommand{\subparagraph}{\@startsection{subparagraph}{5}{\z@}%
  {3.5ex plus 1ex minus .2ex}%
  {-1em plus0.0ex}%
  {\noindent\normalsize\it}}

% General formatting --- for punctuating section headings.
\renewcommand{\@seccntformat}[1]{\@nameuse{the#1}\hspace{1em}}

%=====================================================================
%============================ footnotes ==============================

\renewcommand{\@makefntext}[1]{%
  \parindent=0.25in
  \noindent \hbox to \z@{\hss{\@thefnmark} \hfil}#1}

%=====================================================================
%============================ backmatter =============================

% Environment for formatting all the addresses.
\newenvironment{addresses}%
 {\@@par\let\par\@empty\addvspace{3.25ex}\small\ignorespaces}%
 {\lineskiplimit 1pc\lineskip 1pc\@@par}
% Sub-environment for formatting each individual author's address.
\newenvironment{address}[1][.5\textwidth]%
 {\noindent\ignorespaces\begin{minipage}[t]{#1}\raggedright}%
 {\end{minipage}\allowbreak\ignorespacesafterend}

%=====================================================================
%======================== other environments =========================

% enumerate labeling that won't conflict with standard ex. numbers.
\renewcommand{\theenumi}{\roman{enumi}}
\renewcommand{\labelenumi}{\theenumi.}
\renewcommand{\theenumii}{\alph{enumii}}
\renewcommand{\labelenumii}{\theenumii.}

% list spacing ought to satisfy \itemsep + \parsep < \topsep + \parskip
\def\@listi{\leftmargin\leftmargini
            \parsep 4\p@  \@plus2\p@ \@minus\p@
            \topsep 10\p@ \@plus4\p@ \@minus\p@
            \itemsep4\p@  \@plus2\p@ \@minus\p@}
\let\@listI\@listi
\@listi

% typeset figures with lines above and below and the caption title and
% caption texts in boxes next to each other, top aligned.  these
% definitions extend those of float.sty.
%
% sp caption style
\newlength\floatc@sp@contentwidth
\newcommand\floatc@sp[2]{%
  \setlength\floatc@sp@contentwidth{\linewidth}%
  \addtolength\floatc@sp@contentwidth{-60pt}%
  \parbox[t]{60pt}{{\@fs@cfont#1}}%
  \parbox[t]{\floatc@sp@contentwidth}{#2}}%

% sp float style; uses the sp caption style
\newcommand\fs@sp{
  \def\@fs@cfont{\bfseries}\let\@fs@capt\floatc@sp
  \def\@fs@pre{\hrule\kern5pt}%
  \def\@fs@post{\kern5pt\hrule\relax}%
  \def\@fs@mid{\kern10pt}
  \let\@fs@iftopcapt\iffalse}

% users can override these commands using float.sty's functionality
\floatstyle{sp}
\restylefloat{figure}
\restylefloat{table}

%=====================================================================
%=========================== useful macros ===========================

\def\co{\colon\thinspace}

\DeclareRobustCommand\dash{%
  \unskip\nobreak\thinspace\textemdash\thinspace\ignorespaces}
\pdfstringdefDisableCommands{\renewcommand{\dash}{ - }}

% based on \url defined in hyperref.sty
\DeclareRobustCommand*{\http}{\hyper@normalise\http@}
\def\http@#1{\hyper@linkurl{\Hurl{#1}}{http://#1}}

\newcommand{\email}[1]{\href{mailto:#1}{#1}}

\providecommand{\sv}[1]{\ensuremath{\llbracket{#1}\rrbracket}}

%=====================================================================
%=========================== linguex settings ========================

\if@linguex
  \RequirePackage{linguex}%
  \renewcommand{\firstrefdash}{}%
  \AtBeginDocument{\settowidth{\Exlabelwidth}{(110)}}
\fi

%=====================================================================
%=========================== expex settings ========================

\if@expex
  \RequirePackage{expex}%
  \lingset{%
    exskip=-0.5ex,
    interpartskip=0.5ex,
    aboveexskip=1ex,
    belowexskip=2ex,
    everygla=}
  \def\everyfootnote{%
    \keepexcntlocal
    \excnt=1
    % exskip: sets aboveexskip and belowexskip at the same time
    % exnotype: sets the family for root example numbering (default: arabic)
    %           (must be one of: arabic, chapter.arabic, or roman)
    % sampleexno: sets root example to constant width (default: no constant width)
    % labeltype: sets the family for subexample numbering (default: alpha)
    % labelanchor: sets left alignment of subexample (default: numright)
    % labeloffset: left margin of subexample numbering (default: 1em)
    % textoffset: distance between subexample numbering and text (default: 1em)
    \lingset{exskip=1ex,exnotype=roman,labeloffset=.6em,textoffset=.6em}
  }
  \renewcommand{\@makefntext}[1]{%
    \everyfootnote
    \parindent=0.25in
    \noindent \hbox to \z@{\hss{\@thefnmark} \hfil}#1%
  }
  \gathertags
\fi

%================================ fin ================================
%=====================================================================
