local doc = {}

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


function doc.get_profile(project, profile_name)
    local mainfont = project.options.textual.mainfont or "TeX Gyre Pagella"
    local mathfont = project.options.textual.mathfont or "TeX Gyre Pagella Math"

    local dict = {
        ['abnt'] = {
            papersize = project.options.global.papersize or "a4paper",
            left = "3cm",
            top = "3cm",
            right = "2cm",
            bottom = "2cm",
            bibstyle = project.bibliography.abnt or "abnt-numeric",
            colorlinks = "true",
            linkcolor = "black",
            urlcolor = "black",
            citecolor = "black",
            pdfhighlight = "/N",
            font = function()
                tex.print({
                    [=[\usepackage{setspace}]=],
                    [=[\onehalfspacing]=],
                    [=[\setmainfont{Tex Gyre Heros}]=],
                    [=[\setsansfont{Tex Gyre Heros}]=],
                    [=[\setmathfont{Latin Modern Math}]=]
                })
            end,
            titlesec_style = function()
                tex.print({
                    [=[ \titleformat{\chapter}[block]]=],
                    [=[    {\normalfont\bfseries\filright}]=],
                    [=[    {\thechapter}]=],
                    [=[    {0.3cm}]=],
                    [=[    {\MakeUppercase}]=],
                    [=[    [\vspace{0.3cm}\titlerule]]=],
                    [=[\titleformat{name=\chapter,numberless}[block]]=],
                    [=[    {\normalfont\bfseries\filcenter}{}{0pt}]=],
                    [=[    {\MakeUppercase}]=],
                    [=[    [\vspace{0.3cm}\titlerule]]=],
                    [=[\RenewDocumentCommand{\part}{s o m}{}]=],
                    [=[\fancypagestyle{plain}{]=],
                    [=[  \fancyhf{}]=],
                    [=[  \fancyhead[R]{\thepage}]=],
                    [=[  \renewcommand{\headrulewidth}{0pt}]=],
                    [=[}]=]
                })
            end
        },
        ['default'] = {
            papersize = project.options.global.papersize or "a4paper",
            left = project.options.textual.left or "2.5cm",
            top = project.options.textual.top or "2.5cm",
            right = project.options.textual.right or "2.5cm",
            bottom = project.options.textual.bottom or "2.5cm",
            bibstyle = project.bibliography.style or "numeric-comp",
            colorlinks = project.hyper.setup.colorlinks or "true",
            linkcolor = project.hyper.setup.linkcolor or "blue",
            urlcolor = project.hyper.setup.urlcolor or "blue",
            citecolor = project.hyper.setup.citecolor or "blue",
            pdfhighlight = project.hyper.setup.pdfhighlight or "/N",
            font = function()
                tex.print("\\setmainfont{" .. mainfont .. "}")
                tex.print("\\setsansfont{" .. mainfont .. "}")
                tex.print("\\setmathfont{" .. mathfont .. "}")
            end,
            titlesec_style = function()
                tex.print({
                    [=[\titleformat{\chapter}[display]]]=],
                    [=[    {\normalfont\bfseries}]]=],
                    [=[    {\filleft\LARGE\chaptertitlename\ \thechapter}]]=],
                    [=[    {0.5cm}]]=],
                    [=[    {\titlerule\vspace{0.8cm}\filright\Huge}]]=],
                    [=[    [\vspace{2cm}]]]=],
                    [=[\titleformat{name=\chapter,numberless}[display]]]=],
                    [=[    {\normalfont\bfseries}{}{0pt}]]=],
                    [=[    {\filright\Huge}]]=],
                    [=[    [\vspace{2cm}]]]=],
                    [=[\titlespacing*{\chapter}{0pt}{0pt}{0pt}]=]
                })
            end
        }
    }

    return dict[profile_name]
end

function doc.get_data(project)

    local temp = {}

    temp.type = project.data.type or "Thesis"
    temp.degree = project.data.degree or "(Degree não definido)"
    temp.university = project.data.university or "(Universidade não definida)"
    temp.center = project.data.center or "(Centro não definido)"
    temp.program = project.data.program or "(Programa não definido)"
    temp.edital = project.data.edital or "(Edital não preenchido)"

    temp.title = project.data.title or "(Título não definido)"
    temp.author = project.data.author or "(Autor não definido)"
    temp.date = project.data.date or "(Data não definida)"
            temp.date = string.gsub(temp.date, "/", " de ")
    temp.address = project.data.address or "(Endereço não definido)"
    temp.affiliation = project.data.affiliation or "(Filiação não encontrada)"

    temp.advisor_name = project.advisor[1].name or "(AdvisorName não definido)"
    temp.advisor_role = project.advisor[1].role or "(Advisorrole não definido)"
    temp.advisor_affiliation = project.advisor[1].affiliation or "(Advisoraffiliation não definido)"

    temp.abstract_foreign_name = project.abstract.foreign.name or "(Abstract name is not defined)"
    temp.abstract_foreign_keyword = project.abstract.foreign.keyword or "(Abstract keyword is not defined)"
    temp.abstract_native_name = project.abstract.native.name or "(Resumo nome não definido)"
    temp.abstract_native_keyword = project.abstract.native.keyword or "(Resumo palavra-chave não definida)"

    return temp
end

function doc.input_project()

    local doc_table = {}

    -- 1.a Read config.toml file in root directory
    local user_config_content = read_file("config.toml")
    if not user_config_content then
        print("ERRO: Arquivo config.toml não encontrado na raiz do projeto!")
        return
    end
    -- 1.b Get the used profile
    local profile_select = "default"
    -- If we're tex, then profile_select is the CleanTeXprofile macro
    if token and token.get_macro then
        local p = token.get_macro("CleanTeXprofile")
        if p and p ~= "" then
            profile_select = p
        end
    end
    -- 1.c Read the glossary.toml configurations
    local subglossary_symbols = read_file("frontmatter/glossary_symbols.toml") or ""
    local subglossary_acronyms = read_file("frontmatter/glossary_acronyms.toml") or ""

    -- 2.a Transform config.toml to project lua table
    local project = toml.parse(user_config_content)
    -- 2.c Read the profile.toml
    if profile_select ~= "default" and profile_select ~= "abnt" then
        local profile_path = profile_select .. ".toml"
        local profile_content = read_file(profile_path)
        if profile_content then
            local profile_data = toml.parse(profile_content) -- Transform profile.toml to profile_data project lua table
            -- 3. Merge the two tables: profile overwrites config, if needed
            project = merge_tables(project, profile_data)
        else
            if tex then
                tex.print("\\textbf{Aviso: Perfil " .. profile_select .. ".toml não encontrado!}")
            end
        end
    end

    local profile_name = project.data.compile2abnt and "abnt" or "default"

    doc_table = merge_tables( doc.get_profile(project, profile_name) , doc.get_data(project) )
    doc_table.profile_name = profile_name
    -- 2.b Transform the glossaries tomls to tables in lua
    local sub_glossary_symbols_table = toml.parse(subglossary_symbols)
    local sub_glossary_acronyms_table = toml.parse(subglossary_acronyms)
    doc_table.glossary = merge_tables( sub_glossary_symbols_table, sub_glossary_acronyms_table )

    return doc_table
end

return doc
