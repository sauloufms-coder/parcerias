import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Gestão de Parcerias - Aginova - UFMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const DemandasHome(),
    );
  }
}

class Demanda {
  final String unidade;
  final String coordenador;
  final String instrumento;
  final String tipo;
  final String sei;
  final String servidor;
  final String status;
  final DateTime ultimaAtualizacao;

  Demanda({
    required this.unidade,
    required this.coordenador,
    required this.instrumento,
    required this.tipo,
    required this.sei,
    required this.servidor,
    required this.status,
    required this.ultimaAtualizacao,
  });
}

class DemandasHome extends StatefulWidget {
  const DemandasHome({super.key});

  @override
  State<DemandasHome> createState() => _DemandasHomeState();
}

class _DemandasHomeState extends State<DemandasHome> {
  bool _showFilters = false;
  final List<Demanda> _demandas = [
    Demanda(
      unidade: "FAENG",
      coordenador: "Prof. João",
      instrumento: "TED",
      tipo: "Convênio",
      sei: "23104.000123/2025-11",
      servidor: "Maria",
      status: "Em andamento",
      ultimaAtualizacao: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Demanda(
      unidade: "INBIO",
      coordenador: "Profa. Ana",
      instrumento: "ACT",
      tipo: "Parceria",
      sei: "23104.000456/2025-11",
      servidor: "Carlos",
      status: "Concluído",
      ultimaAtualizacao: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  void _exportarCSV() {
    // Aqui você implementa a lógica de exportar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exportação CSV em andamento...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _demandas.length;
    final exibindo = _demandas.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: const Text(
          'Sistema de Gestão de Parcerias - Aginova - UFMS',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: _showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
            icon: Icon(
              _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            tooltip: "Exportar CSV",
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportarCSV,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade50,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  FilterChip(label: Text("Tipo"), selected: false),
                  FilterChip(label: Text("Instrumento"), selected: false),
                  FilterChip(label: Text("Unidade"), selected: false),
                  FilterChip(label: Text("Status"), selected: false),
                  FilterChip(label: Text("Coordenador"), selected: false),
                  FilterChip(label: Text("Servidor"), selected: false),
                  FilterChip(label: Text("Instituição"), selected: false),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Total de registros: $total | Exibindo: $exibindo",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _demandas.length,
              itemBuilder: (context, index) {
                final d = _demandas[index];
                final dias = DateTime.now().difference(d.ultimaAtualizacao).inDays;
                final atrasado = dias > 2;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DemandaDetalhe(demanda: d),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Unidade: ${d.unidade}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Coordenador: ${d.coordenador}"),
                          Text("Instrumento Jurídico: ${d.instrumento}"),
                          Text("Tipo: ${d.tipo}"),
                          Text("SEI: ${d.sei}"),
                          Text("Servidor responsável: ${d.servidor}"),
                          Text("Status: ${d.status}"),
                          Row(
                            children: [
                              const Text("Última atualização: "),
                              if (atrasado)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: Colors.red,
                                  child: Text(
                                    DateFormat("dd/MM/yyyy HH:mm").format(d.ultimaAtualizacao),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                )
                              else
                                Text(DateFormat("dd/MM/yyyy HH:mm").format(d.ultimaAtualizacao)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DemandaDetalhe extends StatelessWidget {
  final Demanda demanda;

  const DemandaDetalhe({super.key, required this.demanda});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes da Demanda - ${demanda.sei}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Unidade: ${demanda.unidade}", style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Coordenador: ${demanda.coordenador}"),
            Text("Instrumento Jurídico: ${demanda.instrumento}"),
            Text("Tipo: ${demanda.tipo}"),
            Text("SEI: ${demanda.sei}"),
            Text("Servidor responsável: ${demanda.servidor}"),
            Text("Status: ${demanda.status}"),
            Text("Última atualização: ${DateFormat("dd/MM/yyyy HH:mm").format(demanda.ultimaAtualizacao)}"),
          ],
        ),
      ),
    );
  }
}

