-- _engine/build.lua
--
-- 0 - importing doc table
-- 1 - format document
--     - page numbering
--     - set font
--     - packages
--     -style for chapters
-- 2 - config pkgs:
--     - geometry
--     - biblatex
--     - hyperref
--     - glossary
--     - cleveref
-- 3 - pre-textual content
--     - title page
--     - cover page
--     - board approval
--     - authors assent
--     - dedication (optional)
--     - acknowledgments (optional)
--     - epigraph (optional)
--     - abstract native
--     - abstract foreign
--     - list of figures
--     - list of tables
--     - list of acronyms
--     - list of symbols
--     - table of contents
--
--  0. Importing doc table --
--
-- import io module
local docio = require("_engine.docio")

-- input the project
local doc = docio.input_project()

-- check
if not doc then
    tex.print("\\textbf{ERRO FATAL: Arquivo config.toml não encontrado ou inválido.}")
    return
end

--
--  1. Formating document --
--
-- numbering frontmatter pages
if not doc.frontmatter.numbering then
    tex.print({
        [[\makeatletter]],
        [[\renewcommand{\frontmatter}{\cleardoublepage\@mainmatterfalse\pagenumbering{roman}\pagestyle{empty}}]],
        [[\renewcommand{\mainmatter}{\cleardoublepage\@mainmattertrue\pagenumbering{arabic}\pagestyle{plain}}]],
        [[\makeatother]]
    })
end
-- packages
tex.print({
    [=[\usepackage{fontspec}]=],
    [=[\usepackage{unicode-math}]=],
    string.format([[\usepackage[%s]{babel}]], doc.options.global.babel),
    [=[\usepackage{graphicx}]=],
    [=[\usepackage{indentfirst}]=],
    [=[\usepackage{fancyhdr}]=],
    [=[\usepackage{titlesec}]=],
    [=[\usepackage{epigraph}]=],
    [=[\usepackage{caption}]=],
    [=[\usepackage{microtype}]=],
    [=[\usepackage[autostyle]{csquotes}]=],
    [=[\usepackage{booktabs}]=],
    [=[\usepackage{enumitem}]=],
    [=[\usepackage{array}]=],
    [=[\renewcommand{\arraystretch}{1.6}]=],
    [=[\usepackage{pdfpages}]=],
    [=[\usepackage{amsmath}]=]
})
-- set font
doc.font()
-- set style for chapters
doc.titlesec_style()

--
--  2. Configuring packages --
--
-- geometry
tex.print(
    string.format([[\usepackage[%s,left=%s,top=%s,right=%s,bottom=%s]{geometry}]],
    doc.papersize, doc.left, doc.top, doc.right, doc.bottom))
-- biblatex
tex.print({
    [[\usepackage[]],
    string.format([[    style=%s,]], doc.bibstyle),
    [[    backend=biber,]],
    [[    sorting=none,]],
    [[    giveninits=true,]],
    [[    uniquelist=false,]],
    [[    uniquename=false,]],
    [[    natbib=true,]],
    [[    maxcitenames=1,]],
    [[    mincitenames=1]],
    [[]{biblatex}]],
    string.format([[\addbibresource{%s}]], doc.bibliography.file)
})
-- hyperref
tex.print([[\usepackage{hyperref}]])
tex.print(string.format(
    [[\hypersetup{colorlinks=%s, linkcolor=%s, urlcolor=%s, citecolor=%s, pdfhighlight=%s}]],
    doc.colorlinks, doc.linkcolor, doc.urlcolor, doc.citecolor, doc.pdfhighlight
))
tex.print(string.format([[\hypersetup{pdftitle={%s}, pdfauthor={%s}}]], doc.title, doc.author))
tex.print(string.format([[\title{%s}]], doc.title))
tex.print(string.format([[\author{%s}]], doc.author))
-- glossary
if doc.glossary then
    tex.print([[\usepackage[symbols, acronym, nonumberlist]{glossaries}]])
    if doc.frontmatter.listof.acronym or doc.frontmatter.listof.symbols then
        tex.print([[\makeglossaries]])
    end
end
if doc.glossary.acronyms then
    for label, acr in pairs(doc.glossary.acronyms) do
        if acr.short and acr.long then
            local tex_cmd = string.format([[\newacronym{%s}{%s}{%s}]], label, acr.short, acr.long)
            tex.print(tex_cmd)
        end
    end
end
if doc.glossary.symbols then
    for label, sym in pairs(doc.glossary.symbols) do
        if sym.name and sym.description then
            local tex_cmd = string.format([[\newglossaryentry{%s}{name={%s}, description={%s}}]],
                label, sym.name, sym.description)
            tex.print(tex_cmd)
        end
    end
end
-- cleveref
tex.print([[\usepackage{cleveref}]])

--
--  3. Frontmatter --
--
-- Some useful functions
local header = string.format([[%s\\%s\\%s]], doc.university, doc.center, doc.program)
local footer = string.format([[%s\\%s]], doc.address, doc.date)
local names = string.format([[\textbf{Orientado:} %s\\ \textbf{%s:} %s]], doc.author, doc.advisor_role, doc.advisor_name)
local keywords = {
    ['native'] = table.concat(doc.abstract.native.keywords, "; ") .. "." ,
    ['foreign'] = table.concat(doc.abstract.foreign.keywords, "; ") .. "."
}
local function build_abnt_reference()
    local nomes, sobrenome = string.match(doc.author, "^(.*)%s+(%S+)$")
    local author_abnt = doc.author

    if nomes and sobrenome then
        local sobrenome_upper = unicode.utf8.upper(sobrenome)
        author_abnt = sobrenome_upper .. ", " .. nomes
    end

    local advisors_str = "Orientador: " .. doc.advisor_name .. ". "
    if #doc.advisor > 1 then
        local co_advisors = {}
        for i = 2, #doc.advisor do
            table.insert(co_advisors, doc.advisor[i].name or "(Name não definido)")
        end
        if #co_advisors == 1 then
            advisors_str = advisors_str .. "Coorientador: " .. co_advisors[1] .. "."
        else
            advisors_str = advisors_str .. "Coorientadores: " .. table.concat(co_advisors, ", ", 1, #co_advisors - 1) .. " e " .. co_advisors[#co_advisors] .. "."
        end
    end
    return string.format("%s. %s, %s. \\textbf{%s}. %s", author_abnt, doc.affiliation, doc.date, doc.title, advisors_str)
end
local title_formated = {
    ['default'] = string.format([[\textbf{%s}]], doc.title),
    ['abnt'] = build_abnt_reference() -- Executa a função e guarda o texto!
}
function GenerateSignatures()
    local function print_person(person)
        local title = person.title and (person.title .. " ") or ""
        local name = person.name or "Nome não definido"
        local role = person.role or "Membro"
        local affil = person.affiliation and (" -- " .. person.affiliation) or ""
        tex.print("\\vspace{1.2cm}")
        tex.print("\\begin{center}")
        tex.print("\\rule{10cm}{0.5pt} \\\\")
        tex.print("\\textbf{" .. title .. name .. "} \\\\")
        tex.print(role .. affil)
        tex.print("\\end{center}")
    end
    if doc.board then
        for _, person in ipairs(doc.board) do
            print_person(person)
        end
    end
end

-- Title Page
function GenerateTitlePage()
    if doc.frontmatter.titlepage then
        tex.print({
        [[\begin{titlepage}]],
        [[\noindent\begin{minipage}[t][6cm][t]{\textwidth}]],
        [[\begin{center}]],
        header .. [[ \\[2cm] ]],
        string.format([[{\large\bfseries %s}]], doc.author),
        [[\end{center}]],
        [[\end{minipage}]],
        [[\vspace*{\fill}]],
        [[\begin{center}]],
        [[\rule{0.4\linewidth}{0.8pt}\vspace{0.4cm}\par]],
        string.format([[{\bfseries\Large %s \par}]], doc.title),
        [[\vspace{0.3cm}\rule{0.4\linewidth}{0.8pt}\par]],
        [[\end{center}]],
        [[\vspace*{\fill}]],
        [[\noindent\begin{minipage}[b][6cm][b]{\textwidth}]],
        [[\begin{center}]],
        footer,
        [[\end{center}]],
        [[\end{minipage}]],
        [[\end{titlepage}]]
        })
    end
end
-- Cover Page
function GenerateCoverPage()
    if doc.frontmatter.coverpage then
        tex.print({
            [[\cleardoublepage]],
            [[\begin{titlepage}]],
            [[\noindent\begin{minipage}[t][6cm][t]{\textwidth}]],
            [[\begin{center}]],
            header .. [[ \\[2cm] ]],
            string.format([[{\large\bfseries %s}]], doc.author),
            [[\end{center}]],
            [[\end{minipage}]],
            [[\vspace*{\fill}]],
            [[\begin{center}]],
            [[\rule{0.4\linewidth}{0.8pt}\vspace{0.4cm}\par]],
            string.format([[{\bfseries\Large %s \par}]], doc.title),
            [[\vspace{0.3cm}\rule{0.4\linewidth}{0.8pt}\par]],
            [[\end{center}]],
            [[\vspace*{\fill}]],
            [[\noindent\begin{minipage}[b][9cm][b]{\textwidth}]],
            [[\hfill]],
            [[\begin{minipage}[c][3cm][c]{8cm}]],
            string.format([[{\small %s}\\]], doc.presentation),
            [[]],
            [[\vspace{0.5cm}]],
            names,
            [[\end{minipage}\\]],
            [[\vspace*{\fill}]],
            [[\begin{center}]],
            footer,
            [[\end{center}]],
            [[\end{minipage}]],
            [[\end{titlepage}]]
        })
    end
end
-- Approval Page
function GenerateApprovalPage()
    if doc.frontmatter.approvalpage then
        tex.print({
            [[\cleardoublepage]],
            [[\noindent\begin{minipage}[t][3cm][t]{\textwidth}]],
            [[\begin{center}]],
            string.format([[{\large\bfseries %s}\\]], doc.author),
            [[\vspace{1.5cm}]],
            string.format([[\textbf{%s}]],doc.title),
            [[\end{center}]],
            [[\end{minipage}]],
            [[\noindent\begin{minipage}[c][3cm][c]{\textwidth}]],
            [[\hfill]],
            [[\noindent\begin{minipage}[c][3cm][c]{8cm}]],
            string.format([[{\small %s}\\]], doc.presentation),
            [[\end{minipage}]],
            [[\end{minipage}]],
            [[\vspace{0.3cm}]],
            string.format([[{\bfseries %s:}\\]], doc.approval),
            [[\vspace*{\fill}]]
        })
        GenerateSignatures()
    end
end
-- Assent Page
function GenerateAssentPage()
    if doc.frontmatter.assentpage then
        tex.print({
            [[\cleardoublepage]],
            [[\noindent\begin{minipage}[t][3cm][t]{\textwidth}]],
            [[\begin{center}]],
            string.format([[{\large\bfseries %s}\\]], doc.author),
            [[\vspace{1.5cm}]],
            string.format([[\textbf{%s}]],doc.title),
            [[\end{center}]],
            [[\end{minipage}]],
            [[\noindent\begin{minipage}[c][3cm][c]{\textwidth}]],
            [[\hfill]],
            [[\noindent\begin{minipage}[c][3cm][c]{8cm}]],
            string.format([[{\small %s}\\]], doc.presentation),
            [[\end{minipage}]],
            [[\end{minipage}]],
            [[\vspace{0.3cm}]],
            string.format([[{\bfseries %s:}\\]], doc.approval),
            string.format([[{\bfseries %s:}\\]], doc.assent),
            [[\vspace*{\fill}]],
            [[\begin{center}]],
            [[\vspace{1.2cm}]],
            [[\rule{10cm}{0.5pt}\\]],
            string.format([[\textbf{%s}\\]], doc.author),
            string.format([[Orientado --- %s\\]], doc.affiliation),
            [[\end{center}]],
            [[\begin{center}]],
            [[\vspace{1.2cm}]],
            [[\rule{10cm}{0.5pt}\\]],
            string.format([[\textbf{%s}\\]], doc.advisor_name),
            string.format([[%s --- %s\\]], doc.advisor_role, doc.affiliation),
            [[\end{center}]]
        })
    end
end
-- Generate Dedication Page
function GenerateDedicationPage()
    if doc.frontmatter.dedication then
        tex.print({
            [[\cleardoublepage]],
            [[\vspace*{\fill}]],
            [[\hfill]],
            [[\begin{minipage}[c][3cm][c]{6cm}]],
            [[\input{frontmatter/dedication.tex}]],
            [[\end{minipage}]]
        })
    end
end
-- Generate Acknowledgments Page
function GenerateAcknowledgmentsPage()
    if doc.frontmatter.acknowledgments then
        tex.print({
            [[\cleardoublepage]],
            string.format([[\chapter*{%s}]],doc.acknowledgments_page),
            [[\input{frontmatter/acknowledgments.tex}]],
            [[\vspace*{\fill}]]
        })
    end
end
-- Generate Epigraph Page
function GenerateEpigraphPage()
    if doc.frontmatter.epigraph then
        tex.print({
            [[\cleardoublepage]],
            [[\vspace*{\fill}]],
            [[\hfill]],
            [[\begin{minipage}[c][3cm][c]{6cm}]],
            [[\input{frontmatter/epigraph.tex}]],
            [[\end{minipage}]]
        })
    end
end
-- Generate Abstract in Foreign Language
function GenerateAbstractForeign()
    if doc.frontmatter.abstract.foreign then
        tex.print({
            [[\cleardoublepage]],
            [[\begin{center}]],
            [[\vspace{0.5cm}]],
            string.format([[\textbf{%s}]], unicode.utf8.upper(doc.abstract_foreign_name)),
            [[]],
            [[\vspace{0.5cm}]],
            title_formated[doc.profile_name],
            [[]],
            [[\vspace{0.5cm}]],
            [[\end{center}]],
            [[\input{frontmatter/abstract_foreign.tex}\\]],
            [[\vspace{0.5cm}]],
            [[\linebreak]],
            string.format([[\textbf{Keywords: %s}]], keywords['foreign'])
        })
    end
end
-- Generate Abstract in Native Language
function GenerateAbstractNative()
    if doc.frontmatter.abstract.native then
        tex.print({
            [[\cleardoublepage]],
            [[\begin{center}]],
            [[\vspace{0.5cm}]],
            string.format([[\textbf{%s}]], unicode.utf8.upper(doc.abstract_native_name)),
            [[]],
            [[\vspace{0.5cm}]],
            title_formated[doc.profile_name],
            [[]],
            [[\vspace{0.5cm}]],
            [[\end{center}]],
            [[\input{frontmatter/abstract_native.tex}\\]],
            [[\vspace{0.5cm}]],
            [[\linebreak]],
            string.format([[\textbf{Keywords: %s}]], keywords['native'])
        })
    end
end

function GenerateFrontMatter()
    GenerateTitlePage()
    GenerateCoverPage()
    GenerateApprovalPage()
    GenerateAssentPage()
    GenerateDedicationPage()
    GenerateAbstractForeign()
    GenerateAbstractNative()
    if doc.frontmatter.listof.figures then
        tex.print([[\listoffigures]])
    end
    if doc.frontmatter.listof.tables then
        tex.print([[\listoftables]])
    end
    if doc.frontmatter.listof.acronym then
        if doc.frontmatter.glossary.acronyms.nocite then tex.print([=[\glsaddall[types=\acronymtype]]=]) end
        tex.print([=[\printglossary[type=\acronymtype, title={Lista de Siglas}]]=])
    end
    if doc.frontmatter.listof.symbols then
        if doc.frontmatter.glossary.symbols.nocite then tex.print([=[\glsaddall[types=main]]=]) end
        tex.print([=[\printglossary[title={Lista de Símbolos}]]=])
    end
    if doc.frontmatter.toc then
        tex.print([[\tableofcontents]])
    end
end
