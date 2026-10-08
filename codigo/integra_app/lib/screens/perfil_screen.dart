import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_scaffold.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final perfil = auth.perfil;

    return AppScaffold(
      titulo: 'Perfil',
      indiceSelecionado: 3,
      corpo: ListView(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 36,
            child: Text(
              (perfil?.nomeCompleto.isNotEmpty ?? false) ? perfil!.nomeCompleto[0] : '?',
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(perfil?.nomeCompleto ?? '', style: Theme.of(context).textTheme.titleLarge),
          ),
          Center(child: Text(perfil?.email ?? '')),
          const SizedBox(height: 8),
          Center(child: Text(perfil?.area ?? '')),
          const SizedBox(height: 4),
          Center(child: Text(perfil?.papeis.join(', ') ?? '')),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              await auth.sair();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
