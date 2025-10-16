import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html; // usado apenas no web

// ====================== CONFIG API ======================
const String apiBase =
    'https://script.google.com/macros/s/AKfycbyYlbvdTUB00n9YVJspJnS29b_TkXEAkmGKJToQHWCWdyNscmR1F6mcNE5KI2-VJO98jg/exec';
const String apiKey = 's123g456m789';

// ====================== CORES / ESTILO ==================
const _azulPrincipal = Color(0xFF1565C0);
const _bgApp = Color(0xFFE8F0F7);
const _chipBg = Color(0xFFE3F2FD);
const _chipBorder = Color(0xFF1976D2);
const _cardBorder = Color(0xFFE3E8ED);
const _chipText = Colors.black87;

final _df = DateFormat('dd/MM/yyyy HH:mm');

Color _statusColor(String? s) {
  final t = (s ?? '').toLowerCase();
  if (t.contains('conclu') || t.contains('celebrad')) {
    return const Color.fromARGB(255, 97, 253, 105); // verde
  }
  if (t.contains('aguardando valida')) {
    return const Color.fromARGB(255, 250, 250, 48); // amarelo
  }
  return const Color(0xFFD3EAF9); // fallback
}

// ===== helpers específicos para o balão de "Status" =====
Color _statusPillBg(String? s) {
  final t = (s ?? '').toLowerCase();
  if (t.contains('conclu') || t.contains('celebrad')) {
    return const Color.fromARGB(
      255,
      97,
      253,
      105,
    ).withOpacity(0.12); // verde claro
  }
  if (t.contains('aguardando valida')) {
    return const Color.fromARGB(
      255,
      250,
      250,
      48,
    ).withOpacity(0.12); // amarelo claro
  }
  return _chipBg; // padrão azul dos outros balões
}

Color _statusPillBorder(String? s) {
  final t = (s ?? '').toLowerCase();
  if (t.contains('conclu') || t.contains('celebrad')) {
    return const Color.fromARGB(255, 97, 253, 105); // verde
  }
  if (t.contains('aguardando valida')) {
    return const Color.fromARGB(255, 250, 250, 48); // amarelo
  }
  return _chipBorder; // borda padrão azul
}

bool _notEmpty(String? s) => (s ?? '').trim().isNotEmpty;
String _fmtDate(DateTime? dt) => dt == null ? '-' : _df.format(dt);

// Chip padrão (azul) — todos iguais, texto sempre preto
Widget _pill(
  String label,
  String? value, {
  Color? bg,
  Color? border,
  Color? text,
}) {
  if (!_notEmpty(value)) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    margin: const EdgeInsets.only(right: 8, bottom: 8),
    decoration: BoxDecoration(
      color: bg ?? _chipBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: (border ?? _chipBorder).withOpacity(0.50),
        width: 1,
      ),
    ),
    child: Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 15,
        color: text ?? _chipText,
        fontWeight: FontWeight.w400,
      ),
    ),
  );
}

// Chip especial para "Última atualização" — fica vermelho se > 2 dias
Widget _pillUltimaAtualizacao(DateTime? dt) {
  final stale = dt != null && DateTime.now().difference(dt).inDays > 2;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    margin: const EdgeInsets.only(right: 8, bottom: 8),
    decoration: BoxDecoration(
      color: stale ? const Color(0xFFFFCDD2) : _chipBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: stale ? const Color(0xFFE57373) : _chipBorder.withOpacity(0.50),
        width: 1,
      ),
    ),
    child: Text(
      'Última atualização: ${_fmtDate(dt)}',
      style: const TextStyle(
        fontSize: 15,
        color: _chipText, // texto sempre preto
      ),
    ),
  );
}

// ====================== MODELO ==========================
class Demanda {
  final String id;
  final String? descricao;
  final String? unidade;
  final String? coordenador;
  final String? instrumentoJuridico;
  final String? tipo;
  final String? numeroProcessoSei;
  final String? processoSei;
  final String? servidorResponsavel;
  final String? status;
  final DateTime? ultimaAtualizacao;
  final int? vigenciaMeses;
  final num? valor;
  final String? observacoes;
  final DateTime? carimbo;
  final String? email;
  final String? usuario;
  final String? instituicaoParceira;
  final int? row; // índice da linha na planilha, se disponível

  Demanda({
    required this.id,
    this.descricao,
    this.unidade,
    this.coordenador,
    this.instrumentoJuridico,
    this.tipo,
    this.numeroProcessoSei,
    this.processoSei,
    this.servidorResponsavel,
    this.status,
    this.ultimaAtualizacao,
    this.vigenciaMeses,
    this.valor,
    this.observacoes,
    this.carimbo,
    this.email,
    this.usuario,
    this.instituicaoParceira,
    this.row,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  factory Demanda.fromJson(Map<String, dynamic> j) {
    return Demanda(
      id: (j['id'] ?? '').toString(),
      descricao: j['descricao']?.toString(),
      unidade: j['unidade']?.toString(),
      coordenador: j['coordenador']?.toString(),
      instrumentoJuridico: j['instrumento_juridico']?.toString(),
      tipo: j['tipo']?.toString(),
      numeroProcessoSei: j['numero_processo_sei']?.toString(),
      processoSei: j['processo_sei']?.toString(),
      servidorResponsavel: j['servidor_responsavel']?.toString(),
      status: j['status']?.toString(),
      ultimaAtualizacao: _parseDate(j['ultima_atualizacao_status']),
      vigenciaMeses: j['vigencia_meses'] is int
          ? j['vigencia_meses'] as int
          : (j['vigencia_meses'] is num
                ? (j['vigencia_meses'] as num).toInt()
                : null),
      valor: j['valor'] is num ? j['valor'] as num : null,
      observacoes: j['observacoes']?.toString(),
      carimbo: _parseDate(j['carimbo_data_hora']),
      email: j['email']?.toString(),
      usuario: j['usuario']?.toString(),
      instituicaoParceira: j['instituicao_parceira']?.toString(),
      row: j['_row'] is num
          ? (j['_row'] as num).toInt()
          : (j['_row'] is String ? int.tryParse(j['_row']) : null),
    );
  }
}

// ====================== APP =============================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parcerias - AGINOVA/UFMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _azulPrincipal,
        scaffoldBackgroundColor: _bgApp,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ),
      home: const DemandasHome(),
    );
  }
}

// ====================== HOME ============================
class DemandasHome extends StatefulWidget {
  const DemandasHome({super.key});
  @override
  State<DemandasHome> createState() => _DemandasHomeState();
}

class _DemandasHomeState extends State<DemandasHome> {
  // Estado lista/paginação
  final List<Demanda> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 50;
  int _total = 0;

  // controle de ações para evitar duplo clique
  final Set<String> _busy = {};

  Future<T?> _runOnce<T>(String key, Future<T> Function() fn) async {
    if (_busy.contains(key)) return null;
    _busy.add(key);
    try {
      return await fn();
    } finally {
      _busy.remove(key);
    }
  }

  // Exporta a lista de demandas como CSV (web)
  Future<void> _exportCsv() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export disponível apenas no web')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há itens para exportar')),
      );
      return;
    }

    final headers = [
      'ID',
      'Descrição',
      'Unidade',
      'Coordenador',
      'Instrumento Jurídico',
      'Tipo',
      'Nº Processo SEI',
      'Processo SEI',
      'Servidor Responsável',
      'Status',
      'Última Atualização',
      'Vigência (meses)',
      'Valor',
      'Observações',
      'Carimbo',
      'E-mail',
      'Usuário',
      'Instituição Parceira',
    ];

    String escape(String? v) {
      if (v == null) return '';
      final s = v.replaceAll('"', '""');
      return '"$s"';
    }

    final rows = <String>[];
    rows.add(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));
    for (final d in _items) {
      rows.add(
        [
          escape(d.id),
          escape(d.descricao),
          escape(d.unidade),
          escape(d.coordenador),
          escape(d.instrumentoJuridico),
          escape(d.tipo),
          escape(d.numeroProcessoSei),
          escape(d.processoSei),
          escape(d.servidorResponsavel),
          escape(d.status),
          escape(_fmtDate(d.ultimaAtualizacao)),
          d.vigenciaMeses?.toString() ?? '',
          d.valor?.toString() ?? '',
          escape(d.observacoes),
          escape(_fmtDate(d.carimbo)),
          escape(d.email),
          escape(d.usuario),
          escape(d.instituicaoParceira),
        ].join(','),
      );
    }

    final csv = rows.join('\r\n');
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'demandas_${DateTime.now().toIso8601String()}.csv',
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // Busca livre
  final _searchCtrl = TextEditingController();

  // Mostra/oculta filtros
  bool _showFilters = false;

  // Conjuntos de filtros (multiseleção)
  final Set<String> _filtroTipos = {};
  final Set<String> _filtroInstrumentos = {};
  final Set<String> _filtroUnidades = {};
  final Set<String> _filtroStatus = {};
  final Set<String> _filtroCoordenadores = {};
  final Set<String> _filtroServidores = {};
  final Set<String> _filtroInstituicoes = {};

  // Opções (vindas do diag=1) — usadas em filtros e formulário
  List<String> _optTipos = [];
  List<String> _optInstrumentos = [];
  List<String> _optUnidades = [];
  List<String> _optStatus = [];
  List<String> _optCoordenadores = [];
  List<String> _optServidores = [];
  List<String> _optInstituicoes = [];

  bool _loadingOptions = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadOptions().then((_) => _reload(reset: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Quando chega perto do final, carrega mais se possível
      if (_hasMore && !_loading) {
        _reload();
      }
    }
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final uri = Uri.parse(
        apiBase,
      ).replace(queryParameters: {'key': apiKey, 'diag': '1'});
      debugPrint('DEBUG: fetch options from $uri');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      debugPrint('DEBUG: status=${res.statusCode}');
      debugPrint('DEBUG: body=${res.body}');

      if (res.statusCode != 200) {
        final bodySnippet = (res.body ?? '').toString().substring(
          0,
          (res.body.length ?? 0).clamp(0, 1000),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Falha ao carregar opções: ${res.statusCode}. Body: $bodySnippet',
              ),
            ),
          );
        }
        return;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Resposta inválida ao carregar opções (não é JSON)',
              ),
            ),
          );
        }
        debugPrint('DEBUG: resposta não é Map: ${decoded.runtimeType}');
        return;
      }

      final Map<String, dynamic> jsonBody = Map<String, dynamic>.from(decoded);
      if (jsonBody.containsKey('error')) {
        final msg = jsonBody['message'] ?? jsonBody['error'];
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Servidor: $msg')));
        }
        debugPrint('DEBUG: server error: $jsonBody');
        return;
      }

      final rawOpts = jsonBody['opts'] ?? {};
      final Map<String, dynamic> opts = (rawOpts is Map)
          ? Map<String, dynamic>.from(rawOpts)
          : {};

      List<String> toListStrings(dynamic v) {
        if (v == null) return [];
        if (v is List) {
          return v
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if (v is String) return [v];
        return [];
      }

      setState(() {
        _optTipos = toListStrings(opts['tipo']);
        _optInstrumentos = toListStrings(opts['instrumento_juridico']);
        _optUnidades = toListStrings(opts['unidade']);
        _optStatus = toListStrings(opts['status']);
        // preferir "coordenador", fallback para "servidor_responsavel"
        _optCoordenadores = toListStrings(
          opts['coordenador'] ?? opts['servidor_responsavel'],
        );
        _optServidores = toListStrings(
          opts['servidor_responsavel'] ?? opts['coordenador'],
        );
        _optInstituicoes = toListStrings(opts['instituicao_parceira']);
      });
    } catch (err, st) {
      debugPrint('DEBUG: exception in _loadOptions: $err\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar opções: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _reload({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      if (reset) {
        _page = 1;
        _items.clear();
        _hasMore = true;
      }
      _loading = true;
    });

    try {
      final params = <String, String>{
        'key': apiKey,
        'page': '$_page',
        'pageSize': '$_pageSize',
        'orderBy': 'ultima_atualizacao_status',
        'orderDir': 'desc',
      };
      final q = _searchCtrl.text.trim();
      if (q.isNotEmpty) params['q'] = q;

      if (_filtroTipos.isNotEmpty) params['tipo_in'] = _filtroTipos.join(',');
      if (_filtroInstrumentos.isNotEmpty) {
        params['instrumento_juridico_in'] = _filtroInstrumentos.join(',');
      }
      if (_filtroUnidades.isNotEmpty) {
        params['unidade_in'] = _filtroUnidades.join(',');
      }
      if (_filtroStatus.isNotEmpty) {
        params['status_in'] = _filtroStatus.join(',');
      }
      if (_filtroCoordenadores.isNotEmpty) {
        params['coordenador_in'] = _filtroCoordenadores.join(',');
      }
      if (_filtroServidores.isNotEmpty) {
        params['servidor_responsavel_in'] = _filtroServidores.join(',');
      }
      if (_filtroInstituicoes.isNotEmpty) {
        params['instituicao_parceira_in'] = _filtroInstituicoes.join(',');
      }

      final uri = Uri.parse(apiBase).replace(queryParameters: params);
      final r = await http.get(uri, headers: {'Accept': 'application/json'});
      if (r.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Falha ao carregar demandas: ${r.statusCode}'),
            ),
          );
        }
        return;
      }

      final m = json.decode(r.body);
      if (m is! Map) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resposta inválida do servidor')),
          );
        }
        return;
      }

      final dataRaw = m['data'];
      final countRaw = m['count'];
      late List<Demanda> list;
      if (dataRaw is List) {
        try {
          final casted = dataRaw.cast<Map<String, dynamic>>();
          list = casted.map((e) => Demanda.fromJson(e)).toList();
        } catch (e) {
          // fallback: try to parse each item loosely
          list = (dataRaw).map((it) {
            if (it is Map<String, dynamic>) return Demanda.fromJson(it);
            if (it is Map) {
              return Demanda.fromJson(Map<String, dynamic>.from(it));
            }
            return Demanda(id: it.toString());
          }).toList();
        }
      } else {
        list = [];
      }

      final total = (countRaw is num) ? countRaw.toInt() : list.length;

      setState(() {
        _total = total;
        _items.addAll(list);
        _hasMore = _items.length < _total;
        if (_hasMore) _page += 1;
      });
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar demandas: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =============== UI: BOTÃO/CAIXA DE FILTRO =================
  Widget _filterButton({
    required String tituloBase,
    required List<String> opcoes,
    required Set<String> alvo,
  }) {
    final chevron = const Icon(
      Icons.keyboard_arrow_down,
      color: Colors.black54,
    );
    final title = alvo.isEmpty ? tituloBase : '$tituloBase (${alvo.length})';
    return InkWell(
      onTap: () =>
          _openFilterDialog(tituloBase: tituloBase, opcoes: opcoes, alvo: alvo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            chevron,
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterDialog({
    required String tituloBase,
    required List<String> opcoes,
    required Set<String> alvo,
  }) async {
    final searchCtrl = TextEditingController();
    List<String> filtradas = List<String>.from(opcoes);

    await showDialog<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            void applySearch() {
              final s = searchCtrl.text.trim().toLowerCase();
              setInner(() {
                if (s.isEmpty) {
                  filtradas = List<String>.from(opcoes);
                } else {
                  filtradas = opcoes
                      .where((e) => e.toLowerCase().contains(s))
                      .toList();
                }
              });
            }

            return AlertDialog(
              title: Text(tituloBase),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Filtrar opções...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => applySearch(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setInner(() => alvo.addAll(opcoes));
                            setState(() {}); // atualiza botão na tela principal
                          },
                          child: const Text('Selecionar todos'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setInner(() => alvo.clear());
                            setState(() {});
                          },
                          child: const Text('Limpar todos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtradas.length,
                        itemBuilder: (_, i) {
                          final v = filtradas[i];
                          final marcado = alvo.contains(v);
                          return CheckboxListTile(
                            value: marcado,
                            onChanged: (ok) {
                              setInner(() {
                                if (ok == true) {
                                  alvo.add(v);
                                } else {
                                  alvo.remove(v);
                                }
                              });
                              setState(() {});
                            },
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(v),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _page = 1;
                    _reload(reset: true);
                  },
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Aplicar filtros'),
                ),
              ],
            );
          },
        );
      },
    );

    searchCtrl.dispose();
  }

  // substitui o placeholder vazio por uma implementação utilizável
  Future<String?> _showSelectionDialog(
    BuildContext context,
    String label,
    List<String> options,
    String? value,
  ) {
    final filterCtrl = TextEditingController();
    List<String> filtered = List.from(options);
    return showDialog<String>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            void applyFilter(String q) {
              final low = q.trim().toLowerCase();
              setInner(() {
                if (low.isEmpty) {
                  filtered = List.from(options);
                } else {
                  filtered = options
                      .where((e) => e.toLowerCase().contains(low))
                      .toList();
                }
              });
            }

            return AlertDialog(
              title: Text(label),
              content: SizedBox(
                width: 520,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: filterCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Pesquisar...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: applyFilter,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Nenhuma opção'))
                          : Scrollbar(
                              thumbVisibility: true,
                              child: ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final v = filtered[i];
                                  final selected = (v == value);
                                  return ListTile(
                                    title: Text(v),
                                    selected: selected,
                                    onTap: () => Navigator.of(ctx).pop(v),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ====================== HOME ============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _azulPrincipal,
        foregroundColor: Colors.white,
        title: const Text('Sistema de Gestão de Parcerias — AGINOVA/UFMS'),
        actions: [
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: () => _runOnce('export', () async => await _exportCsv()),
            icon: const Icon(Icons.file_download),
          ),
          IconButton(
            tooltip: _showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => _runOnce('reload', () => _reload(reset: true)),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _runOnce('newDemand', () async {
          // Abre nova tela: passa as opções para popular os Dropdowns
          final nova = await Navigator.of(context).push<Demanda>(
            MaterialPageRoute(
              builder: (_) => CadastroDemandaPage(
                optUnidades: _optUnidades,
                optCoordenadores: _optCoordenadores,
                optInstrumentos: _optInstrumentos,
                optTipos: _optTipos,
                optServidores: _optServidores,
                optStatus: _optStatus,
              ),
            ),
          );
          if (nova != null) {
            setState(() {
              _items.insert(0, nova);
              _total += 1;
            });
          }
        }),
        icon: const Icon(Icons.add),
        label: const Text('Nova demanda'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // barra respiro
          Container(height: 10, color: _bgApp),
          // linha de status + busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _searchBox()),
                const SizedBox(width: 8),
                _counterChip('Total', _total),
                const SizedBox(width: 6),
                _counterChip('Exibindo', _items.length),
              ],
            ),
          ),
          if (_showFilters) _filtersRow(),
          const SizedBox(height: 8),
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _listView(),
          ),
          if (_hasMore && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => _runOnce('loadMore', () => _reload()),
                  child: const Text('Carregar mais'),
                ),
              ),
            ),
          if (_loading && _items.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText:
                    'Buscar por texto (descrição, unidade, status, SEI...)',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _reload(reset: true),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _reload(reset: true),
            icon: const Icon(Icons.search),
            label: const Text('Aplicar'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              _searchCtrl.clear();
              _filtroTipos.clear();
              _filtroInstrumentos.clear();
              _filtroUnidades.clear();
              _filtroStatus.clear();
              _filtroCoordenadores.clear();
              _filtroServidores.clear();
              _filtroInstituicoes.clear();
              setState(() {});
              _reload(reset: true);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  Widget _counterChip(String label, int v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Text(
        '$label: $v',
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _filtersRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _loadingOptions
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _filterButton(
                  tituloBase: 'Tipo',
                  opcoes: _optTipos,
                  alvo: _filtroTipos,
                ),
                _filterButton(
                  tituloBase: 'Instrumento',
                  opcoes: _optInstrumentos,
                  alvo: _filtroInstrumentos,
                ),
                _filterButton(
                  tituloBase: 'Unidade',
                  opcoes: _optUnidades,
                  alvo: _filtroUnidades,
                ),
                _filterButton(
                  tituloBase: 'Status',
                  opcoes: _optStatus,
                  alvo: _filtroStatus,
                ),
                _filterButton(
                  tituloBase: 'Coordenador',
                  opcoes: _optCoordenadores,
                  alvo: _filtroCoordenadores,
                ),
                _filterButton(
                  tituloBase: 'Servidor',
                  opcoes: _optServidores,
                  alvo: _filtroServidores,
                ),
                _filterButton(
                  tituloBase: 'Instituição',
                  opcoes: _optInstituicoes,
                  alvo: _filtroInstituicoes,
                ),
              ],
            ),
    );
  }

  Widget _listView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final d = _items[i];
        final sei = d.numeroProcessoSei ?? d.processoSei ?? '';
        final statusClr = _statusPillBorder(d.status);
        final statusBg = _statusPillBg(d.status);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DemandaDetalhePage(
                    d: d,
                    optUnidades: _optUnidades,
                    optCoordenadores: _optCoordenadores,
                    optInstrumentos: _optInstrumentos,
                    optTipos: _optTipos,
                    optServidores: _optServidores,
                    optStatus: _optStatus,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _notEmpty(d.descricao)
                        ? d.descricao!
                        : (_notEmpty(d.unidade) ? d.unidade! : d.id),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_notEmpty(d.unidade)) _pill('Unidade', d.unidade),
                      if (_notEmpty(d.coordenador))
                        _pill('Coordenador', d.coordenador),
                      if (_notEmpty(d.instrumentoJuridico))
                        _pill('Instrumento', d.instrumentoJuridico),
                      if (_notEmpty(d.tipo)) _pill('Tipo', d.tipo),
                      if (_notEmpty(sei)) _pill('SEI', sei),
                      if (_notEmpty(d.servidorResponsavel))
                        _pill('Servidor', d.servidorResponsavel),
                      if (_notEmpty(d.status))
                        _pill(
                          'Status',
                          d.status,
                          bg: statusBg,
                          border: statusClr,
                          text: _chipText,
                        ),
                      _pillUltimaAtualizacao(d.ultimaAtualizacao),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  } // fim de _listView()
} // fecha a classe _DemandasHomeState

// ===================== DETALHE ==========================
class DemandaDetalhePage extends StatelessWidget {
  final Demanda d;
  final List<String> optUnidades;
  final List<String> optCoordenadores;
  final List<String> optInstrumentos;
  final List<String> optTipos;
  final List<String> optServidores;
  final List<String> optStatus;

  const DemandaDetalhePage({
    super.key,
    required this.d,
    this.optUnidades = const [],
    this.optCoordenadores = const [],
    this.optInstrumentos = const [],
    this.optTipos = const [],
    this.optServidores = const [],
    this.optStatus = const [],
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(d.status);

    final rows = <_KV>[
      _KV('Descrição', d.descricao),
      _KV('Unidade', d.unidade),
      _KV('Coordenador', d.coordenador),
      _KV('Instrumento jurídico', d.instrumentoJuridico),
      _KV('Instituição Parceira', d.instituicaoParceira),
      _KV('Tipo', d.tipo),
      _KV('Nº Processo SEI', d.numeroProcessoSei),
      _KV('Processo SEI', d.processoSei),
      _KV('Servidor responsável', d.servidorResponsavel),
      _KV('Status', d.status),
      _KV('Última atualização', _fmtDate(d.ultimaAtualizacao)),
      _KV('Vigência (meses)', d.vigenciaMeses?.toString()),
      _KV(
        'Valor (R\$)',
        d.valor == null ? '-' : 'R\$ ${d.valor!.toStringAsFixed(2)}',
      ),
      _KV('Observações', d.observacoes),
      _KV('Carimbo', _fmtDate(d.carimbo)),
      _KV('E-mail', d.email),
      _KV('Usuário', d.usuario),
      _KV('ID', d.id),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _azulPrincipal,
        foregroundColor: Colors.white,
        title: Text(
          d.unidade?.isNotEmpty == true ? d.unidade! : 'Detalhe da Demanda',
        ),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final edited = await Navigator.of(context).push<Demanda>(
                MaterialPageRoute(
                  builder: (_) => CadastroDemandaPage(
                    optUnidades: optUnidades,
                    optCoordenadores: optCoordenadores,
                    optInstrumentos: optInstrumentos,
                    optTipos: optTipos,
                    optServidores: optServidores,
                    optStatus: optStatus,
                    existing: d,
                  ),
                ),
              );
              if (edited != null) {
                Navigator.of(
                  context,
                ).pop(); // volta para lista para forçar reload (ou atualiza local)
              }
            },
          ),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((d.unidade ?? '').isNotEmpty)
                        _pill('Unidade', d.unidade),
                      if ((d.coordenador ?? '').isNotEmpty)
                        _pill('Coordenador', d.coordenador),
                      if ((d.instrumentoJuridico ?? '').isNotEmpty)
                        _pill('Instrumento', d.instrumentoJuridico),
                      if ((d.tipo ?? '').isNotEmpty) _pill('Tipo', d.tipo),
                      if ((d.numeroProcessoSei ?? '').isNotEmpty)
                        _pill('SEI', d.numeroProcessoSei),
                      if ((d.servidorResponsavel ?? '').isNotEmpty)
                        _pill('Servidor', d.servidorResponsavel),
                      if ((d.status ?? '').isNotEmpty)
                        _pill(
                          'Status',
                          d.status,
                          bg: statusColor.withOpacity(0.12),
                          border: statusColor,
                        ),
                      _pillUltimaAtualizacao(d.ultimaAtualizacao),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...rows.map((kv) => _DetailRow(kv: kv)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KV {
  final String k;
  final String v;
  _KV(String key, String? value) : k = key, v = (value ?? '-');
}

class _DetailRow extends StatelessWidget {
  final _KV kv;
  const _DetailRow({required this.kv});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              kv.k,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(kv.v, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

// ===================== CADASTRO (NOVA TELA) ==========================
class CadastroDemandaPage extends StatefulWidget {
  final List<String> optUnidades;
  final List<String> optCoordenadores;
  final List<String> optInstrumentos;
  final List<String> optTipos;
  final List<String> optServidores;
  final List<String> optStatus;
  final Demanda? existing;

  const CadastroDemandaPage({
    super.key,
    required this.optUnidades,
    required this.optCoordenadores,
    required this.optInstrumentos,
    required this.optTipos,
    required this.optServidores,
    required this.optStatus,
    this.existing,
  });

  @override
  State<CadastroDemandaPage> createState() => _CadastroDemandaPageState();
}

class _CadastroDemandaPageState extends State<CadastroDemandaPage> {
  final _formKey = GlobalKey<FormState>();

  // Campos
  String? _descricao;
  String? _unidade;
  String? _coordenador;
  String? _instrumento;
  String? _tipo;
  String? _sei;
  String? _servidor;
  String? _status;
  String? _instituicao;
  String? _observacoes;
  num? _valor;
  int? _vigenciaMeses;
  String _temSei = 'Não'; // 'Sim' ou 'Não'

  bool _saving = false;
  bool _dialogOpen = false; // evita abrir múltiplos diálogos por tap rápido

  bool get _isEditing => widget.existing != null;
  int? _existingRow;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existing!;
      _descricao = e.descricao;
      _unidade = e.unidade;
      _coordenador = e.coordenador;
      _instrumento = e.instrumentoJuridico;
      _tipo = e.tipo;
      _sei = e.numeroProcessoSei ?? e.processoSei;
      _servidor = e.servidorResponsavel;
      _status = e.status;
      _instituicao = e.instituicaoParceira;
      _observacoes = e.observacoes;
      _valor = e.valor;
      _vigenciaMeses = e.vigenciaMeses;
      _temSei =
          (e.numeroProcessoSei?.isNotEmpty == true ||
              e.processoSei?.isNotEmpty == true)
          ? 'Sim'
          : 'Não';
      _existingRow = e.row;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Demanda'),
        backgroundColor: _azulPrincipal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Descrição
            TextFormField(
              initialValue: _descricao,
              decoration: const InputDecoration(
                labelText: 'Descrição do objeto/projeto',
              ),
              maxLines: 2,
              onSaved: (v) => _descricao = v?.trim(),
              validator: (v) => _notEmpty(v) ? null : 'Informe a descrição',
            ),
            const SizedBox(height: 12),
            // Seletores
            _drop(
              'Unidade',
              widget.optUnidades,
              (v) => setState(() => _unidade = v),
              value: _unidade,
            ),

            // Coordenador: Autocomplete (digitação com sugestões)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final q = textEditingValue.text.trim().toLowerCase();
                  if (q.isEmpty) {
                    return widget.optCoordenadores.take(50);
                  }
                  return widget.optCoordenadores.where(
                    (c) => c.toLowerCase().contains(q),
                  );
                },
                displayStringForOption: (opt) => opt,
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      if (textEditingController.text.isEmpty &&
                          (_coordenador ?? '').isNotEmpty) {
                        textEditingController.text = _coordenador!;
                      }
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Coordenador',
                          suffixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) {
                          _coordenador = v;
                        },
                      );
                    },
                onSelected: (selection) {
                  setState(() {
                    _coordenador = selection;
                  });
                },
              ),
            ),

            _drop(
              'Instrumento jurídico',
              widget.optInstrumentos,
              (v) => setState(() => _instrumento = v),
              value: _instrumento,
            ),
            _drop(
              'Tipo',
              widget.optTipos,
              (v) => setState(() => _tipo = v),
              value: _tipo,
            ),
            _drop(
              'Servidor responsável',
              widget.optServidores,
              (v) => setState(() => _servidor = v),
              value: _servidor,
            ),
            _drop(
              'Status',
              widget.optStatus,
              (v) => setState(() => _status = v),
              value: _status,
            ),
            const SizedBox(height: 12),
            // Existe Processo SEI? (Sim/Não)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                initialValue: _temSei,
                items: ['Sim', 'Não']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Existe Processo SEI?',
                ),
                onChanged: (v) => setState(() => _temSei = v ?? 'Não'),
              ),
            ),
            // Número do Processo SEI (habilitado só se existir)
            TextFormField(
              initialValue: _sei,
              decoration: const InputDecoration(
                labelText: 'Nº Processo SEI / Processo SEI',
              ),
              enabled: _temSei == 'Sim',
              onSaved: (v) => _sei = v?.trim(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _instituicao,
              decoration: const InputDecoration(
                labelText: 'Instituição Parceira',
              ),
              onSaved: (v) => _instituicao = v?.trim(),
            ),
            const SizedBox(height: 12),
            // Vigência, Valor
            TextFormField(
              initialValue: _vigenciaMeses?.toString(),
              decoration: const InputDecoration(labelText: 'Vigência (meses)'),
              keyboardType: TextInputType.number,
              onSaved: (v) {
                final n = int.tryParse((v ?? '').trim());
                _vigenciaMeses = n;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _valor?.toString(),
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onSaved: (v) {
                final s = (v ?? '').replaceAll('.', '').replaceAll(',', '.');
                _valor = num.tryParse(s);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _observacoes,
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
                  onPressed: _saving ? null : _salvar,
                  icon: const Icon(Icons.save),
                  label: _saving
                      ? const Text('Salvando...')
                      : const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _drop(
    String label,
    List<String> options,
    ValueChanged<String?> onChanged, {
    String? value,
    int threshold = 150, // quando maior que isso, abre diálogo pesquisável
  }) {
    if (options.length > threshold) {
      final controller = TextEditingController(text: value ?? '');
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () async {
            if (_dialogOpen || _saving) return; // protege reentrância
            _dialogOpen = true;
            final sel = await _showSelectionDialog(
              context,
              label,
              options,
              value,
            );
            _dialogOpen = false;
            if (sel != null) {
              controller.text = sel; // atualiza campo visível
              onChanged(sel);
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                suffixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      );
    }

    // lista pequena → manter DropdownButtonFormField
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: options
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        decoration: InputDecoration(labelText: label),
        onChanged: (v) {
          if (_saving) return; // evita alterar durante salvamento
          onChanged(v);
        },
      ),
    );
  }

  Future<String?> _showSelectionDialog(
    BuildContext context,
    String label,
    List<String> options,
    String? value,
  ) {
    final filterCtrl = TextEditingController();
    List<String> filtered = List.from(options);
    return showDialog<String>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            void applyFilter(String q) {
              final low = q.trim().toLowerCase();
              setInner(() {
                if (low.isEmpty) {
                  filtered = List.from(options);
                } else {
                  filtered = options
                      .where((e) => e.toLowerCase().contains(low))
                      .toList();
                }
              });
            }

            return AlertDialog(
              title: Text(label),
              content: SizedBox(
                width: 520,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: filterCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Pesquisar...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: applyFilter,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Nenhuma opção'))
                          : Scrollbar(
                              thumbVisibility: true,
                              child: ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final v = filtered[i];
                                  final selected = (v == value);
                                  return ListTile(
                                    title: Text(v),
                                    selected: selected,
                                    onTap: () => Navigator.of(ctx).pop(v),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _salvar() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    _saving = true;
    setState(() {});
    _formKey.currentState!.save();

    final Map<String, String> form = {
      'descricao': _descricao ?? '',
      'unidade': _unidade ?? '',
      'coordenador': _coordenador ?? '',
      'instrumento_juridico': _instrumento ?? '',
      'tipo': _tipo ?? '',
      'processo_sei': _temSei == 'Sim' ? 'Sim' : 'Não',
      'numero_processo_sei': _temSei == 'Sim' ? (_sei ?? '') : '',
      'servidor_responsavel': _servidor ?? '',
      'status': _status ?? '',
      'instituicao_parceira': _instituicao ?? '',
      'observacoes': _observacoes ?? '',
      'vigencia_meses': _vigenciaMeses?.toString() ?? '',
      'valor': _valor?.toString() ?? '',
    };

    if (_isEditing) {
      form['action'] = 'update';
      if (_existingRow != null) form['_row'] = _existingRow!.toString();
      form['id'] = widget.existing!.id;
    } else {
      form['action'] = 'create';
    }
    form['ultima_atualizacao_status'] = DateTime.now().toIso8601String();

    try {
      final uri = Uri.parse(apiBase).replace(queryParameters: {'key': apiKey});
      debugPrint('POST (form) $uri');
      debugPrint('form: $form');

      final res = await http.post(uri, body: form);
      debugPrint('statusCode: ${res.statusCode}');
      debugPrint('body: ${res.body}');

      if (res.statusCode == 200) {
        // Tenta decodificar JSON; aceita vários formatos de resposta
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            final body = decoded;
            if (body['error'] != null) {
              final msg = body['message'] ?? body['error'];
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Servidor: $msg')));
              }
              return;
            }
            if (body['success'] == true && body['data'] != null) {
              final created = Demanda.fromJson(
                Map<String, dynamic>.from(body['data']),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isEditing
                          ? 'Demanda atualizada'
                          : 'Demanda criada com sucesso',
                    ),
                  ),
                );
                Navigator.pop(context, created);
              }
              return;
            }
            if (body['id'] != null) {
              // monta objeto básico a partir dos campos locais + possível _row
              final created = Demanda(
                id: body['id'].toString(),
                descricao: _descricao,
                unidade: _unidade,
                coordenador: _coordenador,
                instrumentoJuridico: _instrumento,
                tipo: _tipo,
                numeroProcessoSei: _sei,
                processoSei: _sei,
                servidorResponsavel: _servidor,
                status: _status,
                ultimaAtualizacao: DateTime.now(),
                vigenciaMeses: _vigenciaMeses,
                valor: _valor,
                observacoes: _observacoes,
                instituicaoParceira: _instituicao,
                row: body['data']?['_row'] is num
                    ? (body['data']['_row'] as num).toInt()
                    : (body['data']?['_row'] is String
                          ? int.tryParse(body['data']['_row'])
                          : null),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isEditing ? 'Demanda atualizada' : 'Demanda criada',
                    ),
                  ),
                );
                Navigator.pop(context, created);
              }
              return;
            }

            // JSON válido mas sem success/id — tratar como sucesso genérico
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isEditing ? 'Demanda atualizada' : 'Demanda enviada',
                  ),
                ),
              );
              Navigator.pop(context);
            }
            return;
          } else {
            // Resposta 200 mas não-JSON (texto) — tratar como sucesso genérico
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isEditing ? 'Demanda atualizada' : 'Demanda criada',
                  ),
                ),
              );
              Navigator.pop(context);
            }
            return;
          }
        } catch (err) {
          // falha ao parsear JSON -> considerar sucesso (server retornou 200)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEditing ? 'Demanda atualizada' : 'Demanda criada',
                ),
              ),
            );
            Navigator.pop(context);
          }
          return;
        }
      }

      // não-200
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falha ao criar/atualizar demanda: ${res.statusCode}',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Erro ao salvar: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      _saving = false;
      if (mounted) setState(() {});
    }
  }
}
