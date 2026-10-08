class Perfil {
  final String id;
  final String nomeCompleto;
  final String email;
  final String area;
  final List<String> papeis;

  Perfil({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    required this.area,
    required this.papeis,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        id: json['id'] as String,
        nomeCompleto: json['nomeCompleto'] as String,
        email: json['email'] as String,
        area: json['area'] as String? ?? '',
        papeis: (json['papeis'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
