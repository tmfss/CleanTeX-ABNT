\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{cleantex}[2025/09/08 CleanTeX Engine - ABNT/Livre]

\LoadClass[oneside, 12pt]{book}

\directlua{dofile("_engine/build.lua")}

\AfterEndPreamble{%
    \frontmatter
    \directlua{GenerateFrontMatter()}
    \mainmatter
    \setcounter{page}{1}
}

\AtEndDocument{%
    \backmatter
    \nocite{*}
    \chapter{Referências}
    \printbibliography[heading=none]%
}
