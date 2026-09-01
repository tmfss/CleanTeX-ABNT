# CleanTeX-ABNT

```CleanTeX-ABNT/
├── _engine/
│   ├── toml.lua                # Parser toml -> lua
│   ├── build.lua               # Arquivo de build do lua para dados e metadados do template
│   └── build.tex               # Arquivo de comunicação build.lua -> LaTeX
├── _preamble/                  
│   └──                         # Arquivos de pré-âmbulo (config) gerais do TeX (colocar macros e titlepage aqui)
├── bib/
│   ├── bib.tex                 # Formatador das referências.
│   └── ref.bib                 # Arquivo .bib: dados das referências.
├── frontmater/                 
│   └── ...                     # Arquivos pré-textuais em TeX
├── chapters/
│   └── ...                     # Pasta dos capítulos do trabalho.
├── figures/
│   └── ...                     # Pasta com figuras do trabalho
├── profiles/
│   ├── ufv.toml                # Perfil de configuração para normas da ufv
│   └── default.toml            # Perfil de configuração para default (padrão internacional)
├── .latexmkrc                  # Arquivo de configuração do latexmk para compilação (PERL)
├── config.toml                 # Arquivo de configuração global (toml)
└── main.tex                    # Ponto de entrada do documento. Totalmente limpo (sem comandos de build e coisas estranhas assim).
```

## 📝 As normas da UFV suportadas automaticamente

O template tem a opção `\UseUFVNorms{True}` para gerar um documento compatível com todas as normas de entrega de trabalho da UFV, segundo a [Normalização de Trabalhos Acadêmicos (2025)](https://www.bbt.ufv.br/wp-content/uploads/2025/02/Normalizacao-de-trabalhos-academicos-2025-UFV.pdf) e o [Manual de Normas e Procedimentos para Submissão de Dissertações e Teses (2025)](https://ppg.ufv.br/wp-content/uploads/2025/08/Manual-de-entrega-de-dissertacoes-e-teses.pdf).

Formatação:
- Fonte Arial ou Times New Roman – tamanho 12
- Papel: A4 (21 cm x 29,7 cm)
- Margens:
    - Superior e esquerda: 3 cm
    - Inferior e direita: 2 cm
- Espaçamento: 1,5
- Numeração: canto superior direito, iniciando no corpo do trabalho

Estrutura pré-textual:
- Capa e Folha de Rosto
- Ficha de Aprovação (gerada automaticamente com espaço para assinaturas)
- Dedicatória (opcional)
- Agradecimentos (obrigatório)
- Epígrafe (opcional)
- Resumo em língua vernácula
- Resumo em língua estrangeira
- Listas de elementos (opcional)
- Sumário

Bibliografia:
- ABNT com citação autor-data ou numérica (ambas permitidas)

### 4. 📚 Fazendo citações

O template usa o padrão `natbib` em conjunto com o Biber/BibLaTeX. Consulte a tabela abaixo para saber qual comando usar no seu texto:

| Comando | Numérica | Autor-ano | ABNT Numérica | ABNT |
| :--- | :--- | :--- | :--- | :--- |
| `\citet{chave}` | Scrutinizer et al. [1] | Scrutinizer et al. (1979) | Scrutinizer et al. (2) | Scrutinizer et al. (1979) |
| `\citep{chave}` | [1] | (Scrutinizer et al., 1979) | (2) | (SCRUTINIZER et al., 1979) |
| `\citeauthor{chave}` | Scrutinizer et al. | Scrutinizer et al. | Scrutinizer et al. | (SCRUTINIZER et al.) |
| `\citeyear{chave}` | 1979 | 1979 | 1979 | (1979) |
| `\citet*{chave}` | Scrutinizer, Lucille e Joe [1] | Scrutinizer, Lucille e Joe (1979) | Scrutinizer; Lucille; Joe (2) | Scrutinizer, Lucille e Joe (1979) |
| `\citep*{chave}` | [1] | (Scrutinizer, Lucille e Joe, 1979) | (2) | (SCRUTINIZER; LUCILLE; JOE, 1979) |
| `\citeauthor*{chave}` | Scrutinizer, Lucille e Joe | Scrutinizer, Lucille e Joe | Scrutinizer; Lucille; Joe | SCRUTINIZER et al.* |
| `\citeyear*{chave}` | 1979 | 1979 | 1979 | 1979 |

## Agradecimentos (Acknowledgments)

O núcleo do **CleanTeX-ABNT** utiliza o interpretador de código aberto [toml2lua](https://github.com/OlegHQ/toml2lua/tree/dev) (sob licença MIT) para realizar o *parsing* nativo dos arquivos de configuração da linguagem TOML para o motor LuaLaTeX. Ficam aqui os créditos e agradecimentos aos desenvolvedores originais por disponibilizarem essa excelente ferramenta estrutural.