# Integra API

Protótipo da API REST descrita no capítulo 6 do PIM ("6 Plataforma web e integração"),
construído com ASP.NET Core 8, Entity Framework Core, SQLite e ASP.NET Core Identity.

> **Status:** protótipo funcional, não revisado/testado em produção. Escrito para
> demonstrar que a proposta do PIM é implementável, não como entrega de software
> pronto para uso real (sem testes automatizados, sem revisão de segurança completa,
> sem HTTPS configurado para produção). O painel administrativo MVC descrito no PIM
> **não foi implementado** nesta etapa — só a API REST consumida pelo app.

## Como rodar

Pré-requisitos: [.NET SDK 8](https://dotnet.microsoft.com/download) instalado.

```bash
cd integra-api
dotnet restore

# Defina a chave do JWT fora do appsettings.json versionado (User Secrets):
dotnet user-secrets init
dotnet user-secrets set "Jwt:Key" "uma-chave-bem-grande-e-aleatoria-apenas-sua"

dotnet run
```

A API sobe em `https://localhost:5001` (ou a porta que o `dotnet run` indicar) e
cria `integra.db` automaticamente na primeira execução, com os papéis, quatro
usuários de teste e os quatro módulos de formação já cadastrados (ver
`Data/SeedData.cs`).

Em ambiente de desenvolvimento, o Swagger fica em `/swagger` (PERES, 2026, p. 100-102:
o Swagger deve ficar restrito ao desenvolvimento).

## Usuários de teste (seed)

| E-mail | Senha | Papel |
|---|---|---|
| colaborador@conecta.com.br | Colaborador123! | Colaborador |
| gestor@conecta.com.br | Gestor123! | Gestor |
| rh@conecta.com.br | RhInclusao123! | RHInclusao |
| admin@conecta.com.br | AdminTec123! | AdminTecnico |

## Endpoints (Quadro 8 do PIM)

| Rota | Descrição |
|---|---|
| `POST /api/auth/login` | Autentica e devolve tokens + perfil |
| `POST /api/auth/refresh` | Renova a sessão (rotação de refresh token) |
| `POST /api/auth/logout` | Invalida o refresh token informado |
| `GET /api/auth/me` | Perfil e papéis do usuário autenticado |
| `GET /api/solicitacoes` | Lista as solicitações do próprio usuário (paginado, filtro por status) |
| `GET /api/solicitacoes/{id}` | Detalha uma solicitação |
| `POST /api/solicitacoes` | Cria uma solicitação (idempotente via `clientRequestId`) |
| `PUT /api/solicitacoes/{id}/cancelamento` | Cancela uma solicitação "Aberta" |
| `GET /api/conteudos` | Lista módulos de formação |
| `GET /api/conteudos/{id}` | Detalha um módulo |
| `GET /api/participacoes/minhas` | Progresso do usuário na formação |
| `POST /api/participacoes` | Conclui um módulo (idempotente) |
| `POST /api/participacoes/{id}/avaliacao` | Envia respostas e recebe a nota |
| `POST /api/relatos` | Registra um relato reservado |
| `GET /api/relatos/meus` | Lista os relatos do próprio autor |
| `GET /api/relatos/{id}` | Detalha um relato próprio |
| `GET /health/live`, `/health/ready` | Verificação de vida/prontidão |

## O que foi simplificado em relação à proposta do PIM

- **Protocolo da solicitação** é gerado de forma simples (não sequencial por empresa);
  no capítulo 6 ele é só ilustrativo.
- **Nota da avaliação** é a média aritmética das respostas enviadas, só para a
  demonstração funcionar — o PIM não especifica o algoritmo de correção.
- **Painel MVC** (gestão de demandas e acompanhamento da formação, Figura 6) não foi
  implementado; só a API que o alimentaria.
- **Rate limiting** usa uma janela fixa simples (5 tentativas/minuto por IP global),
  não por usuário.
