import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/relato_viewmodel.dart';
import '../widgets/app_scaffold.dart';

// Figura 2(d) do PIM: aviso de que o relato é reservado e não anônimo,
// dados do ocorrido e confirmação de ciência antes do envio.
class RelatoScreen extends StatefulWidget {
  const RelatoScreen({super.key});

  @override
  State<RelatoScreen> createState() => _RelatoScreenState();
}

class _RelatoScreenState extends State<RelatoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contextoController = TextEditingController();
  final _descricaoController = TextEditingController();
  DateTime? _data;
  bool _ciente = false;

  @override
  void dispose() {
    _contextoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: agora,
      firstDate: DateTime(agora.year - 1),
      lastDate: agora,
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _enviar(RelatoViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    if (_data == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Informe a data do ocorrido.')));
      return;
    }
    if (!_ciente) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirme que está ciente antes de enviar.')));
      return;
    }

    await vm.enviar(
      data: _data!,
      contexto: _contextoController.text.trim(),
      descricao: _descricaoController.text.trim(),
    );

    if (vm.enviadoComSucesso && mounted) {
      _contextoController.clear();
      _descricaoController.clear();
      setState(() {
        _data = null;
        _ciente = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Relato recebido.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RelatoViewModel>();

    return AppScaffold(
      titulo: 'Relato reservado',
      indiceSelecionado: 2,
      corpo: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline, style: BorderStyle.solid),
                ),
                child: const Text(
                  'Este relato é reservado: visto só pelo RH/inclusão, vinculado à sua '
                  'conta e não anônimo.',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_data == null
                    ? 'Data do ocorrido'
                    : '${_data!.day.toString().padLeft(2, "0")}/'
                        '${_data!.month.toString().padLeft(2, "0")}/${_data!.year}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _selecionarData,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contextoController,
                decoration: const InputDecoration(labelText: 'Contexto'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o contexto.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 5,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Descreva o ocorrido.' : null,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _ciente,
                onChanged: (v) => setState(() => _ciente = v ?? false),
                title: const Text('Li e estou ciente'),
              ),
              if (vm.erro != null) ...[
                const SizedBox(height: 8),
                Text(vm.erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: vm.enviando ? null : () => _enviar(vm),
                child: vm.enviando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar relato'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
