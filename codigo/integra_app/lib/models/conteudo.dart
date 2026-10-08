class Conteudo {
  final int id;
  final String titulo;
  final String modulo;
  final int duracaoMinutos;
  final DateTime atualizadoEm;

  Conteudo({
    required this.id,
    required this.titulo,
    required this.modulo,
    required this.duracaoMinutos,
    required this.atualizadoEm,
  });

  factory Conteudo.fromJson(Map<String, dynamic> json) => Conteudo(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        modulo: json['modulo'] as String,
        duracaoMinutos: json['duracaoMinutos'] as int,
        atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
      );
}

class Participacao {
  final int id;
  final int conteudoId;
  final String conteudoTitulo;
  final bool concluido;
  final DateTime? concluidoEm;
  final num? nota;

  Participacao({
    required this.id,
    required this.conteudoId,
    required this.conteudoTitulo,
    required this.concluido,
    this.concluidoEm,
    this.nota,
  });

  factory Participacao.fromJson(Map<String, dynamic> json) => Participacao(
        id: json['id'] as int,
        conteudoId: json['conteudoId'] as int,
        conteudoTitulo: json['conteudoTitulo'] as String,
        concluido: json['concluido'] as bool,
        concluidoEm: json['concluidoEm'] == null
            ? null
            : DateTime.parse(json['concluidoEm'] as String),
        nota: json['nota'] as num?,
      );
}
