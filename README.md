# CleanTeX-ABNT 🚀

Um template/engine LaTeX modular, limpo e à prova de dores de cabeça (*idiot-proof*). 

O **CleanTeX-ABNT** não é apenas um punhado de macros em TeX. Ele é um motor impulsionado por **LuaLaTeX** que lê arquivos de configuração amigáveis em **TOML**. Isso significa que você **nunca mais precisará mexer em preâmbulos complexos ou macros esquisitas do LaTeX**. Basta preencher seus dados no arquivo `.toml`, focar em escrever o seu texto, e o motor faz o resto.

A ideia é conferir liberdade absoluta para o usuário escrever, gerando automaticamente um documento compatível com as exigências da ABNT ou de universidades específicas (como a UFV), com uma raiz de projeto totalmente limpa.

## 🌲 Árvore de Diretórios

O código é estruturado de forma a separar completamente a configuração, a lógica e o conteúdo:

```Text
CleanTeX-ABNT/
├── _engine/
│   ├── toml.lua                # Parser nativo TOML -> Lua
│   ├── build.lua               # Lógica de construção de dados e metadados
│   └── build.tex               # Ponte de comunicação Lua -> LaTeX
├── _preamble/                  
│   └── ...                     # Arquivos de estilo e formatação base
├── bib/
│   ├── bib.tex                 # Configuração da bibliografia (Biber)
│   └── ref.bib                 # Suas referências em formato BibTeX
├── frontmatter/                 
│   ├── glossary_acronyms.toml  # Suas siglas configuradas em TOML
│   ├── glossary_symbols.toml   # Seus símbolos configurados em TOML
│   └── ...                     # Arquivos de texto (resumo, dedicatória, etc)
├── chapters/
│   └── ...                     # Pasta sugerida para os seus capítulos
├── figures/
│   └── ...                     # Pasta para suas imagens
├── profiles/
│   ├── ufv.toml                # Perfil de regras específicas da UFV
│   └── default.toml            # Perfil padrão internacional/livre
├── .latexmkrc                  # Configuração de compilação automática
├── config.toml                 # ⚙️ SEU ARQUIVO GLOBAL DE CONFIGURAÇÃO
└── main.tex                    # 📝 Ponto de entrada do texto. Totalmente limpo!
```

## ⚙️ Como Funciona (A Magia do TOML)

Diferente dos templates tradicionais, toda a configuração do seu documento é feita no arquivo `config.toml`. Veja como é legível e intuitivo:

```toml
[data]
title = "Título da sua Dissertação/Tese"
author = "Seu Nome Completo"
date = "Fevereiro/2026"
type = "Dissertação"
degree = "Mestre em Física"
compile2abnt = true # Muda automaticamente o layout para normas ABNT!

[frontmatter]
numbering = true
titlepage = true
approvalpage = true
abstract.native = true
listof.figures = false
toc = true
```

O motor Lua lê esse arquivo e constrói dinamicamente todas as páginas pré-textuais, capas, fichas de aprovação e configurações de hiperlinks para você!

### 📚 Glossários e Siglas Simplificados
Até mesmo os glossários são feitos em TOML! Basta editar os arquivos na pasta `frontmatter`:
```toml
[acronyms]
gisc = { short = "GISC", long = "Grupo de Investigação de Sistemas Complexos" }
ufv  = { short = "UFV",  long = "Universidade Federal de Viçosa" }
```
E no seu texto (dententro do `main.tex`), basta usar `\gls{gisc}` ou o atalho configurado `|gisc|`!

## 🚀 Quickstart

Para usar o template, clone o repositório:
```bash
git clone https://github.com/timotheosf/CleanTeX-ABNT.git
```

A compilação do template **exige o LuaLaTeX** e deve ser feita preferencialmente com a ferramenta [`latexmk`](https://mgeier.github.io/latexmk.html). Basta rodar no terminal, na raiz do projeto:
```bash
latexmk main.tex
```
*(O projeto já contém um arquivo `.latexmkrc` configurado).*

**Passo a passo:**
1. **Dados:** Preencha o `config.toml` com suas informações.
2. **Textos Preliminares:** Escreva seus resumos e dedicatórias nos arquivos `.tex` dentro da pasta `frontmatter/`.
3. **Escrita:** Chame seus capítulos no `main.tex`.
4. **Bibliografia:** Adicione suas referências no arquivo `bib/ref.bib`.

## 📝 Normas ABNT e UFV Suportadas Automaticamente

Ao definir `compile2abnt = true` no seu `config.toml` (ou carregar um perfil específico como `ufv.toml`), o motor ajusta o documento para as regras rígidas acadêmicas:

**Formatação Automática:**
- Fonte equivalente à Arial/Times – tamanho 12, espaçamento 1,5.
- Margens ABNT (Superior/Esquerda: 3cm | Inferior/Direita: 2cm).
- Numeração correta iniciando no corpo do texto.

**Estrutura Pré-textual (Gerada sozinha pelo Lua):**
- Capa e Folha de Rosto.
- Ficha de Aprovação e Folha de Assentimento com base nos avaliadores definidos no `config.toml`.
- Resumos, Listas e Sumário integrados.

## 📚 Fazendo Citações

O template usa o padrão Biber/BibLaTeX. Consulte a tabela abaixo para saber qual comando usar no seu texto:

| Comando | Numérica | Autor-ano | ABNT Numérica | ABNT Autor-Data |
| :--- | :--- | :--- | :--- | :--- |
| `\citet{chave}` | Scrutinizer et al. [1] | Scrutinizer et al. (1979) | Scrutinizer et al. (2) | Scrutinizer et al. (1979) |
| `\citep{chave}` | [1] | (Scrutinizer et al., 1979) | (2) | (SCRUTINIZER et al., 1979) |
| `\citeauthor{chave}` | Scrutinizer et al. | Scrutinizer et al. | Scrutinizer et al. | (SCRUTINIZER et al.) |
| `\citeyear{chave}` | 1979 | 1979 | 1979 | (1979) |
| `\citet*{chave}` | Scrutinizer, Lucille e Joe [1] | Scrutinizer, Lucille e Joe (1979) | Scrutinizer; Lucille; Joe (2) | Scrutinizer, Lucille e Joe (1979) |
| `\citep*{chave}` | [1] | (Scrutinizer, Lucille e Joe, 1979) | (2) | (SCRUTINIZER; LUCILLE; JOE, 1979) |

## 🤝 Agradecimentos (Acknowledgments)

O núcleo do **CleanTeX-ABNT** utiliza o interpretador de código aberto [toml2lua](https://github.com/OlegHQ/toml2lua/tree/dev) (sob licença MIT) para realizar o *parsing* nativo dos arquivos de configuração da linguagem TOML para o motor LuaLaTeX. Ficam aqui os créditos e profundos agradecimentos aos desenvolvedores originais por disponibilizarem essa excelente ferramenta estrutural.