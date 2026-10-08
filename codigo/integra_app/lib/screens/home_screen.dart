import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/solicitacao.dart';
import '../viewmodels/solicitacoes_viewmodel.dart';
import '../widgets/app_scaffold.dart';

// Figura 2(b) do PIM: saudação, contadores por status, lista e "Nova solicitação".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SolicitacoesViewModel>().carregar());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SolicitacoesViewModel>();

    return AppScaffold(
      titulo: 'Início e demandas',
      indiceSelecionado: 0,
      acaoFlutuante: FloatingActionButton.extended(
        onPressed: () => _abrirNovaSolicitacao(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova solicitação'),
      ),
      corpo: RefreshIndicator(
        onRefresh: vm.carregar,
        child: _buildConteudo(context, vm),
      ),
    );
  }

  Widget _buildConteudo(BuildContext context, SolicitacoesViewModel vm) {
    if (vm.carregando && vm.itens.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.erro != null && vm.itens.isEmpty) {
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

    final contagens = {
      for (final status in StatusSolicitacao.values)
        status: vm.itens.where((s) => s.status == status).length,
    };

    return ListView(
      children: [
        Row(
          children: [
            _ContadorStatus(label: 'Abertas', valor: contagens[StatusSolicitacao.aberta] ?? 0),
            _ContadorStatus(label: 'Em andamento', valor: contagens[StatusSolicitacao.emAndamento] ?? 0),
            _ContadorStatus(label: 'Concluídas', valor: contagens[StatusSolicitacao.concluida] ?? 0),
          ],
        ),
        const SizedBox(height: 16),
        if (vm.itens.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('Nenhuma solicitação ainda.')),
          )
        else
          ...vm.itens.map((s) => _SolicitacaoCard(solicitacao: s, vm: vm)),
      ],
    );
  }

  void _abrirNovaSolicitacao(BuildContext context) {
    final vm = context.read<SolicitacoesViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioNovaSolicitacao(vm: vm),
    );
  }
}

class _ContadorStatus extends StatelessWidget {
  final String label;
  final int valor;
  const _ContadorStatus({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text('$valor', style: Theme.of(context).textTheme.headlineSmall),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolicitacaoCard extends StatelessWidget {
  final Solicitacao solicitacao;
  final SolicitacoesViewModel vm;
  const _SolicitacaoCard({required this.solicitacao, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${solicitacao.protocolo} · ${solicitacao.titulo}'),
        subtitle: Text('${statusLabel(solicitacao.status)} · '
            '${solicitacao.pendenteDeEnvio ? "Aguardando envio" : _dataCurta(solicitacao.criadoEm)}'),
        trailing: solicitacao.status == StatusSolicitacao.aberta && !solicitacao.pendenteDeEnvio
            ? TextButton(
                onPressed: () => vm.cancelar(solicitacao.id),
                child: const Text('Cancelar'),
              )
            : null,
      ),
    );
  }

  String _dataCurta(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}';
}

class _FormularioNovaSolicitacao extends StatefulWidget {
  final SolicitacoesViewModel vm;
  const _FormularioNovaSolicitacao({required this.vm});

  @override
  State<_FormularioNovaSolicitacao> createState() => _FormularioNovaSolicitacaoState();
}

class _FormularioNovaSolicitacaoState extends State<_FormularioNovaSolicitacao> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  String _categoria = 'Acessos';
  String _prioridade = 'Media';
  bool _enviando = false;

  static const _categorias = ['Acessos', 'Materiais', 'Cadastros', 'Apoio de outra área'];
  static const _prioridades = {'Baixa': 'Baixa', 'Media': 'Média', 'Alta': 'Alta'};

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await widget.vm.criar(
        titulo: _tituloController.text.trim(),
        categoria: _categoria,
        prioridade: _prioridade,
        descricao: _descricaoController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nova solicitação', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o título.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _prioridade,
              decoration: const InputDecoration(labelText: 'Prioridade'),
              items: _prioridades.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _prioridade = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Descreva a solicitação.' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _enviando ? null : _enviar,
              child: _enviando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
