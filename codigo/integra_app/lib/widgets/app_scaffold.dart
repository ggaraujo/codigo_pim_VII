import 'package:flutter/material.dart';

// Casca comum das telas autenticadas: barra inferior de navegação e, em telas
// largas (tablet, >= 600 de largura lógica), um corpo com no máximo 840 de
// largura centralizado (LayoutBuilder/MediaQuery — seção 5.2 do PIM).
class AppScaffold extends StatelessWidget {
  final String titulo;
  final Widget corpo;
  final int indiceSelecionado;
  final Widget? acaoFlutuante;

  const AppScaffold({
    super.key,
    required this.titulo,
    required this.corpo,
    required this.indiceSelecionado,
    this.acaoFlutuante,
  });

  static const _rotas = ['/inicio', '/formacao', '/relato', '/perfil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final larguraLogica = MediaQuery.of(context).size.width;
          final conteudo = Padding(
            padding: const EdgeInsets.all(16),
            child: corpo,
          );
          if (larguraLogica >= 600) {
            // Layout de tablet: conteúdo centralizado com largura máxima.
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: conteudo,
              ),
            );
          }
          return conteudo;
        },
      ),
      floatingActionButton: acaoFlutuante,
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceSelecionado,
        onDestinationSelected: (i) {
          if (i == indiceSelecionado) return;
          Navigator.of(context).pushReplacementNamed(_rotas[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Formação'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Relato'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
