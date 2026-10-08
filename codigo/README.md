# Integra – protótipo de código (PIM VII)

Este diretório contém o código-fonte do protótipo funcional citado na introdução e na
conclusão do PIM VII: uma implementação simplificada, mas funcional, do aplicativo
mobile (capítulo 5) e da API REST (capítulo 6) descritos na proposta da plataforma
**Integra**.

> **Este código não foi compilado, executado nem testado neste ambiente** (sem SDK do
> .NET nem do Flutter disponíveis aqui). Foi escrito e revisado manualmente, mas a
> verificação final (compilar, rodar, testar os fluxos) é de responsabilidade de quem
> for publicá-lo e rodá-lo.

## Estrutura

```text
codigo/
  integra-api/   API REST em ASP.NET Core 8 (.NET), EF Core + SQLite, Identity, JWT
  integra_app/   Aplicativo em Flutter (Dart), MVVM com Provider
```

Cada subprojeto tem seu próprio `README.md` com instruções de instalação, execução e
a lista do que foi simplificado em relação à proposta completa do PIM.

## Como publicar no GitHub

Este código foi apenas montado localmente — ninguém o enviou a um repositório. Para
publicá-lo:

```bash
# 1. Dentro da pasta codigo/, inicialize um repositório Git
cd codigo
git init
git add .
git commit -m "Protótipo inicial: API ASP.NET Core + app Flutter (PIM VII)"

# 2. Crie um repositório vazio no GitHub (pelo site ou via gh CLI)
gh repo create SEU-USUARIO/integra-pim-vii --public --source=. --remote=origin
# (ou crie manualmente em github.com/new e depois:)
# git remote add origin https://github.com/SEU-USUARIO/integra-pim-vii.git

# 3. Envie o código
git branch -M main
git push -u origin main
```

Depois de publicar, copie o link do repositório e substitua o placeholder
`[LINK DO REPOSITÓRIO GITHUB]` nos dois pontos em que ele aparece no trabalho:

- `PIM_VII_Integra.docx` (um trecho na introdução, um na conclusão — ambos destacados
  em amarelo para facilitar a busca);
- se preferir editar a fonte em Markdown, também em `conteudo/05_INTRODUCAO.md` e
  `conteudo/12_CONCLUSAO.md`.

## O que este protótipo demonstra — e o que não demonstra

Ele demonstra que a proposta descrita nos capítulos 5 e 6 é implementável: os
endpoints da API, o modelo de dados, a autenticação por token, as quatro telas do
aplicativo e a fila offline simplificada existem como código real, coerente com os
contratos e fluxos especificados no trabalho.

Ele **não** demonstra que a solução foi testada, implantada ou validada com usuários
reais — isso continua sendo tratado no trabalho como proposto/esperado (capítulo 7).
Também não inclui o painel administrativo MVC (seção 6.4), testes automatizados, nem
os projetos nativos Android/iOS do Flutter (gerados por `flutter create .`, conforme
`integra_app/README.md`).
