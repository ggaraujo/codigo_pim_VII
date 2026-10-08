import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conteudo.dart';
import '../viewmodels/formacao_viewmodel.dart';
import '../widgets/app_scaffold.dart';

// Figura 2(c) do PIM: trilhas com módulos, duração e progresso.
class FormacaoScreen extends StatefulWidget {
  const FormacaoScreen({super.key});

  @override
  State<FormacaoScreen> createState() => _FormacaoScreenState();
}

class _FormacaoScreenState extends State<FormacaoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<FormacaoViewModel>().carregar());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FormacaoViewModel>();

    return AppScaffold(
      titulo: 'Formação',
      indiceSelecionado: 1,
      corpo: RefreshIndicator(
        onRefresh: vm.carregar,
        child: _buildConteudo(context, vm),
      ),
    );
  }

  Widget _buildConteudo(BuildContext context, FormacaoViewModel vm) {
    if (vm.carregando && vm.conteudos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.erro != null && vm.conteudos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vm.erro!),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: vm.carregar, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    return ListView(
      children: vm.conteudos.map((c) => _ModuloCard(conteudo: c, vm: vm)).toList(),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final Conteudo conteudo;
  final FormacaoViewModel vm;
  const _ModuloCard({required this.conteudo, required this.vm});

  @override
  Widget build(BuildContext context) {
    final concluido = vm.concluido(conteudo.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conteudo.titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${conteudo.modulo} · ${conteudo.duracaoMinutos ~/ 60}h '
                '${concluido ? "· concluído" : ""}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: concluido ? 1.0 : 0.0),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('Ler')),
                const SizedBox(width: 8),
                if (!concluido)
                  FilledButton(
                    onPressed: () => vm.concluirModulo(conteudo.id),
                    child: const Text('Concluir'),
                  )
                else
                  FilledButton(onPressed: () {}, child: const Text('Avaliação')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
