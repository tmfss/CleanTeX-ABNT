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


-- 2.a Transform config.toml to project lua table
project = toml.parse(user_config_content)
-- 2.b Read the profile.toml
local profile_path = profile_name .. ".toml"
local profile_content = read_file(profile_path)
if profile_content then
    local profile_data = toml.parse(profile_content) -- Transform profil.toml to profile_data project lua table
    
    -- 3. Merge the two tables: profile overwrites config, if needed
    project = merge_tables(project, profile_data)
else
    if tex then 
        tex.print("\\textbf{Aviso: Perfil " .. profile_name .. ".toml não encontrado!}") 
    end
end
is_ptbr = (project.options.global.babel == "brazilian")

if is_ptbr then
    aproval = "APROVADO:"
    assent = "ASSENTIMENTO:"
else
    aproval = "APPROVED:"
    assent = "ASSENT:"
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

    -- 1. Imprime o(s) Orientador(es)
    if project.advisor then
        for _, person in ipairs(project.advisor) do
            print_person(person)
        end
    end

    -- 2. Imprime o(s) Coorientador(es)
    if project.coadvisor then
        for _, person in ipairs(project.coadvisor) do
            print_person(person)
        end
    end

    -- 3. Imprime os Membros da Banca
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

function GeneratePresentation()
    local doc_type = project.metadata.type or "Thesis"
    local degree = project.metadata.degree or "Mestre"
    local university = project.metadata.university or "Universidade Não Definida"
    local edital = project.metadata.edital or "[Edital não preenchido]"

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