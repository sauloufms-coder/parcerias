import 'package:flutter/material.dart';

// A standalone replacement/alternative for the original CadastroDemandaPage
// that uses DropdownButtonFormField for many fields and allows an "Other"
// choice to enter a custom value.
//
// Usage: push this page with the option lists you already fetch in your app.
// On save it returns a Map<String, String> (form values) via Navigator.pop(context, result).
class CadastroDemandaPageDropdowns extends StatefulWidget {
  final List<String> optEmails;
  final List<String> optServidores;
  final List<String> optCoordenadores;
  final List<String> optTipoNatureza; // e.g. ['Novo','Aditivo','Alteração']
  final List<String> optInstrumentos;
  final List<String> optUnidades;
  final List<String> optInstituicoes;
  final List<String> optProcessosSei;
  final List<String> optNumerosSei;
  final List<String> optStatus;

  const CadastroDemandaPageDropdowns({
    super.key,
    this.optEmails = const [],
    this.optServidores = const [],
    this.optCoordenadores = const [],
    this.optTipoNatureza = const ['Novo', 'Aditivo', 'Alteração'],
    this.optInstrumentos = const [],
    this.optUnidades = const [],
    this.optInstituicoes = const [],
    this.optProcessosSei = const [],
    this.optNumerosSei = const [],
    this.optStatus = const [],
  });

  @override
  State<CadastroDemandaPageDropdowns> createState() =>
      _CadastroDemandaPageDropdownsState();
}

class _CadastroDemandaPageDropdownsState
    extends State<CadastroDemandaPageDropdowns> {
  final _formKey = GlobalKey<FormState>();

  // form fields
  String? _descricao;

  String? _email;
  bool _emailOther = false;
  String? _emailOtherValue;

  String? _servidor;
  bool _servidorOther = false;
  String? _servidorOtherValue;

  String? _coordenador;
  bool _coordenadorOther = false;
  String? _coordenadorOtherValue;

  String? _natureza; // Novo / Aditivo / Alteração

  String? _instrumento;
  bool _instrumentoOther = false;
  String? _instrumentoOtherValue;

  String? _unidade;
  bool _unidadeOther = false;
  String? _unidadeOtherValue;

  String? _instituicao;
  bool _instituicaoOther = false;
  String? _instituicaoOtherValue;

  String? _processoSei;
  bool _processoSeiOther = false;
  String? _processoSeiOtherValue;

  String? _numeroSei;
  bool _numeroSeiOther = false;
  String? _numeroSeiOtherValue;

  String? _status;

  int? _vigenciaMeses;
  num? _valor;
  String? _observacoes;

  bool _saving = false;

  // helper to build dropdown with "Other" option
  Widget _dropdownWithOther({
    required String label,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    required bool otherFlag,
    required void Function(bool) setOtherFlag,
    required String? otherValue,
    required ValueChanged<String?> onOtherChanged,
    String? hint,
  }) {
    final items = [
      const DropdownMenuItem<String>(
        value: '',
        child: Text('—'),
      ),
      ...options.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      const DropdownMenuItem<String>(value: '__other__', child: Text('Outro...')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: otherFlag ? '__other__' : (value ?? ''),
          items: items,
          decoration: InputDecoration(labelText: label, hintText: hint),
          onChanged: (v) {
            if (v == '__other__') {
              setOtherFlag(true);
              onChanged(null);
            } else {
              setOtherFlag(false);
              onChanged(v == '' ? null : v);
            }
          },
          validator: (v) {
            if (label == 'Descrição') return null;
            // don't enforce anything here; leave validation to form-level if needed
            return null;
          },
        ),
        if (otherFlag)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              initialValue: otherValue,
              decoration: InputDecoration(labelText: '$label (outro)'),
              onChanged: onOtherChanged,
              validator: (s) {
                if ((s ?? '').trim().isEmpty) return 'Informe $label';
                return null;
              },
            ),
          ),
      ],
    );
  }

  String? _pickEffective(String? selected, bool otherFlag, String? otherVal) {
    if (otherFlag) return otherVal?.trim();
    return (selected ?? '').trim().isEmpty ? null : selected;
  }

  void _onSave() {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final result = <String, String>{};

    result['descricao'] = _descricao?.trim() ?? '';

    result['email'] = _pickEffective(_email, _emailOther, _emailOtherValue) ?? '';
    result['servidor_responsavel'] =
        _pickEffective(_servidor, _servidorOther, _servidorOtherValue) ?? '';
    result['coordenador'] =
        _pickEffective(_coordenador, _coordenadorOther, _coordenadorOtherValue) ??
            '';
    result['natureza'] = _natureza ?? '';
    result['instrumento_juridico'] =
        _pickEffective(_instrumento, _instrumentoOther, _instrumentoOtherValue) ??
            '';
    result['unidade'] =
        _pickEffective(_unidade, _unidadeOther, _unidadeOtherValue) ?? '';
    result['instituicao_parceira'] = _pickEffective(
            _instituicao, _instituicaoOther, _instituicaoOtherValue) ??
        '';
    result['processo_sei'] =
        _pickEffective(_processoSei, _processoSeiOther, _processoSeiOtherValue) ??
            '';
    result['numero_processo_sei'] =
        _pickEffective(_numeroSei, _numeroSeiOther, _numeroSeiOtherValue) ?? '';
    result['status'] = _status ?? '';
    result['vigencia_meses'] = _vigenciaMeses?.toString() ?? '';
    result['valor'] = _valor?.toString() ?? '';
    result['observacoes'] = _observacoes ?? '';

    setState(() => _saving = true);
    // Here we simply pop the filled form to caller. The caller can perform the POST.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const spacing = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Demanda (dropdowns)'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Descrição
            TextFormField(
              decoration: const InputDecoration(labelText: 'Descrição do objeto/projeto'),
              maxLines: 2,
              onSaved: (v) => _descricao = v?.trim(),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Informe a descrição' : null,
            ),
            spacing,

            // Email (dropdown + other)
            _dropdownWithOther(
              label: 'E-mail',
              options: widget.optEmails,
              value: _email,
              onChanged: (v) => _email = v,
              otherFlag: _emailOther,
              setOtherFlag: (b) {
                setState(() => _emailOther = b);
              },
              otherValue: _emailOtherValue,
              onOtherChanged: (v) => _emailOtherValue = v,
              hint: 'Selecione um e-mail ou escolha Outro...',
            ),
            spacing,

            // Servidor responsável
            _dropdownWithOther(
              label: 'Servidor responsável',
              options: widget.optServidores,
              value: _servidor,
              onChanged: (v) => _servidor = v,
              otherFlag: _servidorOther,
              setOtherFlag: (b) => setState(() => _servidorOther = b),
              otherValue: _servidorOtherValue,
              onOtherChanged: (v) => _servidorOtherValue = v,
            ),
            spacing,

            // Coordenador
            _dropdownWithOther(
              label: 'Coordenador',
              options: widget.optCoordenadores,
              value: _coordenador,
              onChanged: (v) => _coordenador = v,
              otherFlag: _coordenadorOther,
              setOtherFlag: (b) => setState(() => _coordenadorOther = b),
              otherValue: _coordenadorOtherValue,
              onOtherChanged: (v) => _coordenadorOtherValue = v,
            ),
            spacing,

            // Natureza (Novo / Aditivo / Alteração)
            DropdownButtonFormField<String>(
              value: _natureza,
              decoration: const InputDecoration(labelText: 'Natureza'),
              items: widget.optTipoNatureza
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _natureza = v),
            ),
            spacing,

            // Instrumento jurídico
            _dropdownWithOther(
              label: 'Instrumento jurídico',
              options: widget.optInstrumentos,
              value: _instrumento,
              onChanged: (v) => _instrumento = v,
              otherFlag: _instrumentoOther,
              setOtherFlag: (b) => setState(() => _instrumentoOther = b),
              otherValue: _instrumentoOtherValue,
              onOtherChanged: (v) => _instrumentoOtherValue = v,
            ),
            spacing,

            // Unidade
            _dropdownWithOther(
              label: 'Unidade',
              options: widget.optUnidades,
              value: _unidade,
              onChanged: (v) => _unidade = v,
              otherFlag: _unidadeOther,
              setOtherFlag: (b) => setState(() => _unidadeOther = b),
              otherValue: _unidadeOtherValue,
              onOtherChanged: (v) => _unidadeOtherValue = v,
            ),
            spacing,

            // Instituição parceira
            _dropdownWithOther(
              label: 'Instituição Parceira',
              options: widget.optInstituicoes,
              value: _instituicao,
              onChanged: (v) => _instituicao = v,
              otherFlag: _instituicaoOther,
              setOtherFlag: (b) => setState(() => _instituicaoOther = b),
              otherValue: _instituicaoOtherValue,
              onOtherChanged: (v) => _instituicaoOtherValue = v,
            ),
            spacing,

            // Processo SEI (dropdown + other)
            _dropdownWithOther(
              label: 'Processo SEI',
              options: widget.optProcessosSei,
              value: _processoSei,
              onChanged: (v) => _processoSei = v,
              otherFlag: _processoSeiOther,
              setOtherFlag: (b) => setState(() => _processoSeiOther = b),
              otherValue: _processoSeiOtherValue,
              onOtherChanged: (v) => _processoSeiOtherValue = v,
            ),
            spacing,

            // Número SEI (dropdown + other)
            _dropdownWithOther(
              label: 'Nº Processo SEI',
              options: widget.optNumerosSei,
              value: _numeroSei,
              onChanged: (v) => _numeroSei = v,
              otherFlag: _numeroSeiOther,
              setOtherFlag: (b) => setState(() => _numeroSeiOther = b),
              otherValue: _numeroSeiOtherValue,
              onOtherChanged: (v) => _numeroSeiOtherValue = v,
            ),
            spacing,

            // Status
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: '', child: Text('—')),
                ...widget.optStatus.map(
                  (e) => DropdownMenuItem(value: e, child: Text(e)),
                )
              ],
              onChanged: (v) => setState(() => _status = (v == '' ? null : v)),
            ),
            spacing,

            // Vigência e Valor
            TextFormField(
              decoration: const InputDecoration(labelText: 'Vigência (meses)'),
              keyboardType: TextInputType.number,
              onSaved: (v) {
                final n = int.tryParse((v ?? '').trim());
                _vigenciaMeses = n;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onSaved: (v) {
                final s = (v ?? '').replaceAll('.', '').replaceAll(',', '.');
                _valor = num.tryParse(s);
              },
            ),
            spacing,

            TextFormField(
              decoration: const InputDecoration(labelText: 'Observações'),
              maxLines: 3,
              onSaved: (v) => _observacoes = v?.trim(),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _onSave,
                  icon: const Icon(Icons.save),
                  label: _saving ? const Text('Salvando...') : const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}