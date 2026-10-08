# Integra App

Protótipo do aplicativo mobile descrito no capítulo 5 do PIM ("5 Aplicativo mobile"),
em Flutter, consumindo a API do diretório `integra-api/`.

> **Status:** protótipo funcional, não revisado/testado em dispositivo real nem em
> loja de aplicativos. Implementa as quatro telas da Figura 2 (login, início/demandas,
> formação, relato reservado) e o perfil, com MVVM via Provider, rotas nomeadas com
> guarda, tokens em armazenamento seguro e uma fila offline simplificada para novas
> solicitações. Não inclui testes automatizados nem cache completo de conteúdos
> (ver "O que foi simplificado" abaixo).

## Como rodar

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado
(`flutter doctor` sem erros) e a `integra-api` rodando.

Este repositório traz só o código Dart (`lib/`, `pubspec.yaml`) — os projetos nativos
de Android/iOS (pastas `android/`, `ios/`) são gerados pelo próprio Flutter e não
foram incluídos. Para criá-los:

```bash
cd integra_app
flutter create .      # gera android/, ios/, web/ etc. em volta do lib/ existente
flutter pub get
```

Depois, rode apontando para o endereço da API:

```bash
# Emulador Android (10.0.2.2 é o host da máquina dentro do emulador):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000

# iOS simulator / Flutter web / desktop, rodando a API na mesma máquina:
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

Use um dos usuários de teste do `integra-api/README.md` (ex.:
`colaborador@conecta.com.br` / `Colaborador123!`) para entrar.

## Estrutura

```text
lib/
  main.dart                  Rotas nomeadas (/login, /inicio, /formacao, /relato, /perfil) e guarda
  models/                    Solicitacao, Conteudo, Participacao, Perfil
  services/
    api_service.dart         Cliente HTTP, renovação de sessão, idempotência
    secure_storage_service.dart  Tokens no KeyStore/Keychain
    offline_queue_service.dart   Fila local (SQLite) para novas solicitações
    api_exception.dart       Erros por status HTTP (400/401/403/404/429/5xx)
  viewmodels/                Estado de cada tela (ChangeNotifier + Provider)
  screens/                   As quatro telas da Figura 2 + perfil
  widgets/app_scaffold.dart  Casca comum: barra inferior + layout responsivo (tablet)
```

## O que foi simplificado em relação à proposta do PIM

- **Fila offline** (seção 5.5) foi implementada só para a criação de novas
  solicitações, que é o fluxo mais detalhado no PIM. Conclusão de módulos de
  formação exige conexão nesta versão.
- **Cache local de conteúdos** (SQLite) não foi implementado; a tela de Formação
  busca sempre da API. A fila de solicitações pendentes, sim, usa SQLite
  (`offline_queue_service.dart`), como no PIM.
- **Sincronização automática ao reconectar** não foi implementada — o método
  `SolicitacoesViewModel.sincronizarFila()` existe e funciona, mas precisa ser
  chamado manualmente (ex.: em um listener de conectividade) para rodar sozinho.
- **Testes automatizados** (unitários, de widget, de integração — seção 5.5 do
  PIM) não foram escritos nesta etapa.
- Sem publicação em loja de aplicativos; roda só em modo de desenvolvimento.
