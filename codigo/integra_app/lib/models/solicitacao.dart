// Modelo da solicitação (RF02/RF03 — Quadro 2 do PIM) e seus estados.
enum StatusSolicitacao { aberta, emAndamento, concluida, cancelada }

StatusSolicitacao statusFromString(String s) {
  switch (s) {
    case 'EmAndamento':
      return StatusSolicitacao.emAndamento;
    case 'Concluida':
      return StatusSolicitacao.concluida;
    case 'Cancelada':
      return StatusSolicitacao.cancelada;
    case 'Aberta':
    default:
      return StatusSolicitacao.aberta;
  }
}

String statusLabel(StatusSolicitacao s) {
  switch (s) {
    case StatusSolicitacao.aberta:
      return 'Aberta';
    case StatusSolicitacao.emAndamento:
      return 'Em andamento';
    case StatusSolicitacao.concluida:
      return 'Concluída';
    case StatusSolicitacao.cancelada:
      return 'Cancelada';
  }
}

class Solicitacao {
  final int id;
  final String protocolo;
  final String titulo;
  final String categoria;
  final String prioridade;
  final String descricao;
  final StatusSolicitacao status;
  final String? responsavelNome;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  // true quando o registro ainda está só localmente, aguardando envio
  // (fila offline — seção 5.5 do PIM). Não vem da API.
  final bool pendenteDeEnvio;

  Solicitacao({
    required this.id,
    required this.protocolo,
    required this.titulo,
    required this.categoria,
    required this.prioridade,
    required this.descricao,
    required this.status,
    required this.criadoEm,
    required this.atualizadoEm,
    this.responsavelNome,
    this.pendenteDeEnvio = false,
  });

  factory Solicitacao.fromJson(Map<String, dynamic> json) => Solicitacao(
        id: json['id'] as int,
        protocolo: json['protocolo'] as String,
        titulo: json['titulo'] as String,
        categoria: json['categoria'] as String,
        prioridade: json['prioridade'] as String,
        descricao: json['descricao'] as String,
        status: statusFromString(json['status'] as String),
        responsavelNome: json['responsavelNome'] as String?,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
      );

  // Representa uma solicitação ainda não enviada, criada a partir da fila local.
  factory Solicitacao.pendente({
    required String clientRequestId,
    required String titulo,
    required String categoria,
    required String prioridade,
    required String descricao,
  }) =>
      Solicitacao(
        id: 0,
        protocolo: 'Aguardando envio',
        titulo: titulo,
        categoria: categoria,
        prioridade: prioridade,
        descricao: descricao,
        status: StatusSolicitacao.aberta,
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
        pendenteDeEnvio: true,
      );
}
