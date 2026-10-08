import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/formacao_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/relato_screen.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/formacao_viewmodel.dart';
import 'viewmodels/relato_viewmodel.dart';
import 'viewmodels/solicitacoes_viewmodel.dart';

void main() {
  runApp(const IntegraApp());
}

class IntegraApp extends StatelessWidget {
  const IntegraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..verificarSessao()),
        ChangeNotifierProvider(create: (_) => SolicitacoesViewModel()),
        ChangeNotifierProvider(create: (_) => FormacaoViewModel()),
        ChangeNotifierProvider(create: (_) => RelatoViewModel()),
      ],
      child: MaterialApp(
        title: 'Integra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F5D62)),
          useMaterial3: true,
        ),
        initialRoute: '/login',
        onGenerateRoute: _gerarRota,
      ),
    );
  }

  // Rotas nomeadas (/login, /inicio, /formacao, /relato, /perfil) com guarda:
  // sem sessão válida, qualquer rota protegida leva ao login (seção 5.1 do PIM;
  // MONTEIRO, 2026, p. 105-106).
  Route<dynamic> _gerarRota(RouteSettings settings) {
    final rotasProtegidas = <String, WidgetBuilder>{
      '/inicio': (_) => const HomeScreen(),
      '/formacao': (_) => const FormacaoScreen(),
      '/relato': (_) => const RelatoScreen(),
      '/perfil': (_) => const PerfilScreen(),
    };

    if (settings.name == '/login') {
      return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
    }

    final builder = rotasProtegidas[settings.name];
    if (builder == null) {
      return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _GuardaDeRota(builder: builder),
    );
  }
}

// Consulta o AuthViewModel antes de montar a tela protegida; redireciona ao
// /login quando não há sessão válida.
class _GuardaDeRota extends StatelessWidget {
  final WidgetBuilder builder;
  const _GuardaDeRota({required this.builder});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    switch (auth.estado) {
      case EstadoAuth.desconhecido:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case EstadoAuth.naoAutenticado:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        });
        return const Scaffold(body: SizedBox.shrink());
      case EstadoAuth.autenticado:
        return builder(context);
    }
  }
}
