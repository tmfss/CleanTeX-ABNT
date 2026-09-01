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
local profile_path = "profiles/" .. profile_name .. ".toml"
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