-- _engine/build.lua
-- Load the toml2lua parser 
local toml = require("_engine.toml")
-- Function to read files
local function read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end
-- Function to merge tables
local function merge_tables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            merge_tables(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

-- 1.a Read config.toml file in root directory
local user_config_content = read_file("config.toml")
if not user_config_content then
    print("ERRO: Arquivo config.toml não encontrado na raiz do projeto!")
    return
end
-- 1.b Get the used profile
profile_name = "default"
-- If we're tex, then profile_name is the CleanTeXprofile macro
if token and token.get_macro then
    local p = token.get_macro("CleanTeXprofile")
    if p and p ~= "" then
        profile_name = p
    end
end
-- 1.c Read the glossary.toml configurations
local subglossary_symbols = read_file("frontmatter/glossary_symbols.toml")
local subglossary_acronyms = read_file("frontmatter/glossary_acronyms.toml")

-- 2.a Transform config.toml to project lua table
project = toml.parse(user_config_content)
-- 2.b Transform the glossaries tomls to tables in lua
local sub_glossary_symbols_table = toml.parse(subglossary_symbols)
local sub_glossary_acronyms_table = toml.parse(subglossary_acronyms)
glossary = merge_tables( sub_glossary_symbols_table, sub_glossary_acronyms_table )
-- 2.c Read the profile.toml
if profile_name~="default" and profile_name~="abnt" then
local profile_path = profile_name .. ".toml"
local profile_content = read_file(profile_path)
if profile_content then
    local profile_data = toml.parse(profile_content) -- Transform profile.toml to profile_data project lua table  
    -- 3. Merge the two tables: profile overwrites config, if needed
    project = merge_tables(project, profile_data)
else
    if tex then 
        tex.print("\\textbf{Aviso: Perfil " .. profile_name .. ".toml não encontrado!}") 
    end
end
end

if project.data.compile2abnt then
    profile_name = "abnt"
end

if not project.frontmatter.numbering then
    tex.print([[\makeatletter]])
    tex.print([[\renewcommand{\frontmatter}{%
        \cleardoublepage\@mainmatterfalse\pagenumbering{roman}\pagestyle{empty}%
    }]])
    tex.print([[\renewcommand{\mainmatter}{%
        \cleardoublepage\@mainmattertrue\pagenumbering{arabic}\pagestyle{plain}%
    }]])
    tex.print([[\makeatother]])
end

function SetFont()
    if profile_name == "abnt" then
        tex.print("\\usepackage{setspace}")
        tex.print("\\onehalfspacing")
        tex.print("\\setmainfont{Tex Gyre Heros}")
        tex.print("\\setsansfont{Tex Gyre Heros}")
        tex.print("\\setmathfont{Latin Modern Math}")
    else
        local mainfont = project.options.textual.mainfont or "TeX Gyre Pagella"
        local mathfont = project.options.textual.mathfont or "TeX Gyre Pagella Math"
        tex.print("\\setmainfont{" .. mainfont .. "}")
        tex.print("\\setsansfont{" .. mainfont .. "}")
        tex.print("\\setmathfont{" .. mathfont .. "}")
    end
end

if profile_name == "abnt" then
    doc_papersize = project.options.global.papersize or "a4papper"
    doc_left = "3cm"
    doc_top = "3cm"
    doc_right = "2cm"
    doc_bottom = "2cm"
    doc_bibstyle = project.bibliography.abnt or "abnt-numeric"
    doc_colorlinks = "true"
    doc_linkcolor = "black"
    doc_urlcolor = "black"
    doc_citecolor = "black"
    doc_pdfhighlight = "/N"
else
    doc_papersize = project.options.global.papersize or "a4papper"
    doc_left = project.options.textual.left or "2.5cm"
    doc_top = project.options.textual.top or "2.5cm"
    doc_right = project.options.textual.right or "2.5cm"
    doc_bottom = project.options.textual.bottom or "2.5cm"
    doc_bibstyle = project.bibliography.style or "numeric-comp"
    doc_colorlinks = project.hyper.setup.colorlinks or "true"
    doc_linkcolor = project.hyper.setup.linkcolor or "blue"
    doc_urlcolor = project.hyper.setup.urlcolor or "blue"
    doc_citecolor = project.hyper.setup.citecolor or "blue"
    doc_pdfhighlight = project.hyper.setup.pdfhighlight or "/N"
end

function GenerateSignatures()
    -- Função auxiliar que cospe o LaTeX de uma única linha de assinatura
    local function print_person(person)
        -- Fallbacks de segurança: se o usuário esqueceu de preencher algo no TOML
        local title = person.title and (person.title .. " ") or ""
        local name = person.name or "Nome não definido"
        local role = person.role or "Membro"
        local affil = person.affiliation and (" -- " .. person.affiliation) or ""

        -- Injeta os comandos LaTeX na memória
        tex.print("\\vspace{1.2cm}")
        tex.print("\\begin{center}")
        tex.print("\\rule{10cm}{0.5pt} \\\\")
        tex.print("\\textbf{" .. title .. name .. "} \\\\")
        tex.print(role .. affil)
        tex.print("\\end{center}")
    end

    if project.board then
        for _, person in ipairs(project.board) do
            print_person(person)
        end
    end
end

function GenerateNames()
    local function print_person(person)
        local name = person.name or "Nome não definido"
        local role = person.role or "Orientador"

        tex.print("\\textbf{" .. role .. ":} " ..name .. "\\\\")
    end
    if project.advisor then
        for _, person in ipairs(project.advisor) do
            print_person(person)
        end
    end
end

is_ptbr = (project.options.global.babel == "brazilian")

if is_ptbr then
    approval = "APROVADO:"
    assent = "ASSENTIMENTO:"
    acknowledgments_page = "Agradecimentos"
    
else
    approval = "APPROVED:"
    assent = "ASSENT:"
    acknowledgments_page = "Acknowledgments"
end

local doc_type = project.data.type or "Thesis"
local degree = project.data.degree or "(Degree não definido)"
local university = project.data.university or "(Universidade não definida)"
local center = project.data.center or "(Centro não definido)"
local program = project.data.program or "(Programa não definido)"
local edital = project.data.edital or "(Edital não preenchido)"

local doc_title = project.data.title or "(Título não definido)"
local doc_author = project.data.author or "(Autor não definido)"
local doc_date = project.data.date or "(Data não definida)"
doc_date = string.gsub(doc_date, "/", " de ")
local doc_address = project.data.address or "(Endereço não definido)"
local doc_affiliation = project.data.affiliation or "(Filiação não encontrada)"

local doc_advisor_name = project.advisor[1].name or "(AdvisorName não definido)"
local doc_advisor_role = project.advisor[1].role or "(Advisorrole não definido)"
local doc_advisor_affiliation = project.advisor[1].affiliation or "(Advisoraffiliation não definido)"

local abstract_foreign_name = project.abstract.foreign.name or "(Abstract name is not defined)"
local abstract_foreign_keyword = project.abstract.foreign.keyword or "(Abstract keyword is not defined)"
local abstract_native_name = project.abstract.native.name or "(Resumo nome não definido)"
local abstract_native_keyword = project.abstract.native.keyword or "(Resumo palavra-chave não definida)"

function GeneratePresentation()
    if is_ptbr then
        if doc_type == "relatório" or doc_type == "relatorio" then
            tex.sprint("Relatório apresentado à " .. university .. " como parte do cumprimento das exigências do edital " .. edital .. ".")
        else 
            tex.sprint(doc_type .. " apresentada à " .. university .. " como parte das exigências para obtenção do título de " .. degree .. ".")
        end
    else
        tex.sprint(doc_type .. " submitted to " .. university .. " as part of the requirements to obtain the degree of " .. degree .. ".")
    end
end

function GenerateHeader()
    tex.print(university .. "\\\\")
    tex.print(center .. "\\\\")
    tex.print(program .. "\\\\")
end

function GenerateFooter()
    tex.print(doc_address .. "\\\\")
    tex.print(doc_date .. "\\\\")
end

function GenerateABNTCitation()
    local nomes, sobrenome = string.match(doc_author, "^(.*)%s+(%S+)$")
    local author_abnt = doc_author
    
    if nomes and sobrenome then
        local sobrenome_upper = unicode.utf8.upper(sobrenome)
        author_abnt = sobrenome_upper .. ", " .. nomes
    end

    local advisors_str = ""
    advisors_str = advisors_str .. "Orientador: " .. doc_advisor_name .. ". "
    if #project.advisor > 1 then
        local co_advisors = {}
        for i = 2, #project.advisor do
            table.insert(co_advisors, project.advisor[i].name or "(Name não definido)")
        end
        if #co_advisors == 1 then
            advisors_str = advisors_str .. "Coorientador: " .. co_advisors[1] .. "."
        else
            advisors_str = advisors_str .. "Coorientadores: " .. table.concat(co_advisors, ", ", 1, #co_advisors - 1) .. " e " .. co_advisors[#co_advisors] .. "."
        end
    end
    local reference = string.format("%s. %s, %s. \\textbf{%s}. %s", 
        author_abnt, doc_affiliation, doc_date, doc_title, advisors_str)
    tex.sprint(reference)
end

function GenerateBigTitle()
    tex.sprint("\\begin{center}")
    tex.sprint("\\rule{0.4\\linewidth}{0.8pt}\\vspace{0.4cm}\\par")
    tex.sprint("{\\bfseries\\Large " .. doc_title .. " \\par}")
    tex.sprint("\\vspace{0.3cm}\\rule{0.4\\linewidth}{0.8pt}\\par")
    tex.sprint("\\end{center}")
end

function GenerateTitlePage()
    if project.frontmatter.titlepage then
    tex.sprint("\\begin{titlepage}")
    tex.sprint("\\noindent\\begin{minipage}[t][6cm][t]{\\textwidth}")
    tex.sprint("    \\begin{center}")
    GenerateHeader()
    tex.sprint("        \\vspace{2cm}")
    tex.sprint("")
    tex.sprint("        {\\large \\textbf{" .. doc_author .. "}}")
    tex.sprint("    \\end{center}")
    tex.sprint("\\end{minipage}")
    tex.sprint("")
    tex.sprint("\\vspace*{\\fill}")
    GenerateBigTitle()
    tex.sprint("\\vspace*{\\fill}")
    tex.sprint("")
    tex.sprint("\\noindent\\begin{minipage}[b][6cm][b]{\\textwidth}")
    tex.sprint("    \\begin{center}")
    GenerateFooter()
    tex.sprint("    \\end{center}")
    tex.sprint("\\end{minipage}")
    tex.sprint("\\end{titlepage}")
    end
end

function GenerateCoverPage()
    if project.frontmatter.coverpage then
    tex.sprint("\\cleardoublepage")
    tex.sprint("\\begin{titlepage}")
    tex.sprint("\\noindent\\begin{minipage}[t][9cm][t]{\\textwidth}")
    tex.sprint("    \\begin{center}")
    tex.sprint("        {\\large \\textbf{" .. doc_author .. "}}")
    tex.sprint("    \\end{center}")
    tex.sprint("\\end{minipage}")
    tex.sprint("")
    tex.sprint("\\vspace*{\\fill}")
    GenerateBigTitle()
    tex.sprint("\\vspace*{\\fill}")
    tex.sprint("")
    tex.sprint("\\begin{minipage}[b][9cm][b]{\\textwidth}")
    tex.sprint("\\hfill")
    tex.sprint("\\begin{minipage}[c][3cm][c]{8cm}")
    tex.sprint("\\small{")
    GeneratePresentation()
    tex.sprint("}")
    tex.sprint("\\vspace{0.5cm}")
    tex.sprint("\\linebreak")
    tex.sprint("")
    tex.sprint("\\textbf{Orientado:} " .. doc_author .. "\\\\")
    GenerateNames()
    tex.sprint("\\end{minipage}")
    tex.sprint("\\vspace*{\\fill}")
    tex.sprint("\\begin{center}")
    GenerateFooter()
    tex.sprint("\\end{center}")
    tex.sprint("\\end{minipage}")
    tex.sprint("\\end{titlepage}")
    end
end

function GenerateApprovalPage()
    if project.frontmatter.approvalpage then
    tex.sprint("\\cleardoublepage")
    tex.sprint("\\noindent\\begin{minipage}[t][3cm][t]{\\textwidth}")
    tex.sprint("    \\begin{center}")
    tex.sprint("        {\\large \\textbf{" .. doc_author .. "}}\\\\")
    tex.sprint("        \\vspace{1.5cm}")
    tex.sprint("")
    tex.sprint("        \\textbf{" .. doc_title .. "}")
    tex.sprint("    \\end{center}")
    tex.sprint("\\end{minipage}\\\\")
    tex.sprint("\\begin{minipage}[c][3cm][c]{\\textwidth}")
    tex.sprint("\\hfill")
    tex.sprint("\\begin{minipage}[c][3cm][c]{8cm}")
    tex.sprint("\\small{")
    GeneratePresentation()
    tex.sprint("}")
    tex.sprint("\\end{minipage}")
    tex.sprint("\\vspace{0.3cm}")
    tex.sprint("\\end{minipage}")
    tex.sprint("")
    tex.sprint("\\linebreak")
    tex.sprint("\\textbf{".. approval .."}")
    tex.sprint("\\vspace*{\\fill}")
    GenerateSignatures()
    end
end

function GenerateAssentPage()
    if project.frontmatter.assentpage then
    tex.sprint("\\cleardoublepage")
    tex.sprint("\\noindent\\begin{minipage}[t][3cm][t]{\\textwidth}")
    tex.sprint("    \\begin{center}")
    tex.sprint("        {\\large \\textbf{" .. doc_author .. "}}\\\\")
    tex.sprint("        \\vspace{1.5cm}")
    tex.sprint("")
    tex.sprint("        \\textbf{" .. doc_title .. "}")
    tex.sprint("    \\end{center}")
    tex.sprint("\\end{minipage}\\\\")
    tex.sprint("\\begin{minipage}[c][3cm][c]{\\textwidth}")
    tex.sprint("\\hfill")
    tex.sprint("\\begin{minipage}[c][3cm][c]{8cm}")
    tex.sprint("\\small{")
    GeneratePresentation()
    tex.sprint("}")
    tex.sprint("\\end{minipage}")
    tex.sprint("\\vspace{0.3cm}")
    tex.sprint("\\end{minipage}")
    tex.sprint("")
    tex.sprint("\\linebreak")
    tex.sprint("\\textbf{".. approval .."}\\\\")
    tex.sprint("\\linebreak")
    tex.sprint("\\textbf{".. assent .."}")
    tex.sprint("\\vspace*{\\fill}")
    tex.sprint("\\begin{center}")
    tex.sprint("\\vspace{1.2cm}")
    tex.sprint("\\rule{10cm}{0.5pt}\\\\")
    tex.sprint("\\textbf{".. doc_author .. "}\\\\")
    tex.sprint("Orientado --- " .. doc_affiliation)
    tex.sprint("\\end{center}")
    tex.sprint("")
    tex.sprint("\\begin{center}")
    tex.sprint("\\vspace{1.2cm}")
    tex.sprint("\\rule{10cm}{0.5pt}\\\\")
    tex.sprint("\\textbf{" .. doc_advisor_name .."}\\\\")
    tex.sprint(doc_advisor_role .. " --- " .. doc_advisor_affiliation )
    tex.sprint("")
    tex.sprint("\\end{center}")
    end
end

function GenerateDedicationPage()
    if project.frontmatter.dedication then
    tex.sprint("\\cleardoublepage")
    tex.sprint("\\vspace*{\\fill}")
    tex.sprint("\\hfill")
    tex.sprint("\\begin{minipage}[c][3cm][c]{6cm}")
    tex.sprint("\\input{frontmatter/dedication.tex}")
    tex.sprint("\\end{minipage}")
    end
end

function GenerateAcknowledgmentsPage()
    if project.frontmatter.acknowledgments then
    tex.sprint("\\cleardoublepage")
    tex.sprint("\\chapter*{" .. acknowledgments_page .. "}")
    tex.sprint("\\input{frontmatter/acknowledgments.tex}")
    tex.sprint("\\vspace*{\\fill}")
    end
end

function GenerateEpigraphPage()
    if project.frontmatter.epigraph then
    tex.sprint("\\cleardoublepage")
    tex.sprint("\\vspace*{\\fill}")
    tex.sprint("\\hfill")
    tex.sprint("\\begin{minipage}[c][3cm][c]{6cm}")
    tex.sprint("    \\input{frontmatter/epigraph.tex}")
    tex.sprint("\\end{minipage}")
    end
end

function GenerateKeywords(lang)
    local keys = ""
    if lang == "native" then
        keys = table.concat(project.abstract.native.keywords, "; ") .. "."
        tex.sprint("\\noindent\\textbf{" .. abstract_native_keyword .. ":} ")
        tex.sprint(keys)
    elseif lang == "foreign" then
        keys = table.concat(project.abstract.foreign.keywords, "; ") .. "."
        tex.sprint("\\noindent\\textbf{" .. abstract_foreign_keyword .. ":} ")
        tex.sprint(keys)
    end
end

function GenerateAbstractForeign()
    if project.frontmatter.abstract.foreign then
    tex.sprint("\\cleardoublepage")
    tex.sprint("\\begin{center}")
    tex.sprint("    \\vspace{0.5cm}")
    tex.sprint("    \\textbf{" .. unicode.utf8.upper(abstract_foreign_name) .. "}\\\\")
    if profile_name == "abnt" then
        tex.sprint("\\vspace{1cm}")
        tex.sprint("\\begin{minipage}{0.8\\textwidth}")
        GenerateABNTCitation()
        tex.sprint("\\end{minipage}")
    else
        tex.sprint("    \\vspace{0.5cm}")
        tex.sprint("    \\textbf{" .. doc_title .. "}\\\\")
    end
    tex.sprint("    \\vspace{0.5cm}")
    tex.sprint("\\end{center}")
    tex.sprint("\\input{frontmatter/abstract_foreign.tex}\\\\")
    tex.sprint("\\vspace{0.5cm}")
    tex.sprint("\\linebreak")
    GenerateKeywords("foreign")
    end
end

function GenerateAbstractNative()
    if project.frontmatter.abstract.native then
    tex.sprint("\\cleardoublepage")
    tex.sprint("\\begin{center}")
    tex.sprint("    \\vspace{0.5cm}")
    tex.sprint("    \\textbf{" .. unicode.utf8.upper(abstract_native_name) .. "}\\\\")
    if profile_name == "abnt" then
        tex.sprint("\\vspace{1cm}")
        tex.sprint("\\begin{minipage}{0.8\\textwidth}")
        GenerateABNTCitation()
        tex.sprint("\\end{minipage}")
    else
        tex.sprint("    \\vspace{0.5cm}")
        tex.sprint("    \\textbf{" .. doc_title .. "}\\\\")
    end
    tex.sprint("    \\vspace{0.5cm}")
    tex.sprint("\\end{center}")
    tex.sprint("\\input{frontmatter/abstract_native.tex}\\\\")
    tex.sprint("\\vspace{0.5cm}")
    tex.sprint("\\linebreak")
    GenerateKeywords("native")
    end
end

function GenerateGlossaryMap(gloss)
    if not glossary then return end

    if gloss == "acronyms" and glossary.acronyms then
        for label, acr in pairs(glossary.acronyms) do
            if acr.short and acr.long then
                -- \newacronym{sus}{SUS}{Sistema Único de Saúde}
                local tex_cmd = string.format("\\newacronym{%s}{%s}{%s}", label, acr.short, acr.long)
                tex.sprint(tex_cmd)
            end
        end

    elseif gloss == "symbols" and glossary.symbols then
        for label, sym in pairs(glossary.symbols) do
            if sym.name and sym.description then
                local tex_cmd = string.format("\\newglossaryentry{%s}{name={%s}, description={%s}}", 
                    label, sym.name, sym.description)
                tex.sprint(tex_cmd)
            end
        end
    end
end

function UseGlossary()
    if not glossary then return end
    tex.print("\\usepackage[symbols, acronym, nonumberlist]{glossaries}")
    if project.frontmatter.listof.acronym or project.frontmatter.listof.symbols then
        tex.print("\\makeglossaries")
    end
end

function GenerateFrontMatter()
    GenerateTitlePage()
    GenerateCoverPage()
    GenerateApprovalPage()
    GenerateAssentPage()
    GenerateDedicationPage()
    GenerateAcknowledgmentsPage()
    GenerateEpigraphPage()
    GenerateAbstractNative()
    GenerateAbstractForeign()
    if project.frontmatter.listof.figures then
        tex.sprint("\\listoffigures")
    end
    if project.frontmatter.listof.tables then
        tex.sprint("\\listoftables")
    end
    if project.frontmatter.listof.acronym then
        if project.frontmatter.glossary.acronyms.nocite then tex.sprint("\\glsaddall[types=\\acronymtype]") end
        tex.sprint("\\printglossary[type=\\acronymtype, title={Lista de Siglas}]")
    end
    if project.frontmatter.listof.symbols then
        if project.frontmatter.glossary.symbols.nocite then tex.sprint("\\glsaddall[types=main]") end
        tex.sprint("\\printglossary[title={Lista de Símbolos}]")
    end
    if project.frontmatter.toc then
        tex.sprint("\\tableofcontents")
    end
end