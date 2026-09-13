import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Gestão de Metas Financeiras ("Caixinhas") do aplicativo COGITO.
/// Organiza reservatórios de economia para objetivos específicos com indicadores visuais de progresso,
/// suporte a aportes diários, edições, exclusões, estados de conclusão e sincronização em tempo real via Firestore.
class MetasFinanceirasPage extends StatefulWidget {
  const MetasFinanceirasPage({super.key});

  @override
  MetasFinanceirasPageState createState() => MetasFinanceirasPageState();
}

/// Estado público da [MetasFinanceirasPage].
class MetasFinanceirasPageState extends State<MetasFinanceirasPage>
    with SingleTickerProviderStateMixin {
  /// Controller das sub-abas ("Em Andamento" vs "Concluídas").
  late final TabController _tabController;

  /// Instância do serviço Firebase Firestore.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Obter o identificador único do cliente logado (prioriza FirebaseAuth e fallback no usuarioLogado em memória).
  String _getClienteId() {
    return FirebaseFirestoreService.idClienteAtual;
  }

  /// Exibe modal interativo para criação de uma nova meta financeira ("Caixinha").
  void exibirDialogoNovaMeta() {
    final tituloController = TextEditingController();
    final objetivoController = TextEditingController(text: 'R\$ 0,00');
    final inicialController = TextEditingController(text: 'R\$ 0,00');
    String categoriaSelecionada = 'Reserva';
    final List<String> categorias = [
      'Reserva',
      'Viagem',
      'Veículo',
      'Imóvel',
      'Educação',
      'Outros',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(Icons.savings_outlined, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text('Nova Meta Financeira'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: InputDecoration(
                        labelText: 'Nome da Meta (ex: Viagem de Férias)',
                        prefixIcon: const Icon(
                          Icons.flag_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: objetivoController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _formatarMoedaEmTempoReal(val, objetivoController),
                      decoration: InputDecoration(
                        labelText: 'Valor Objetivo',
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: inicialController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _formatarMoedaEmTempoReal(val, inicialController),
                      decoration: InputDecoration(
                        labelText: 'Saldo Inicial Guardado',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoriaSelecionada,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: categorias
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => categoriaSelecionada = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String titulo = tituloController.text.trim();
                    final double objetivo = _extrairValorMoeda(
                      objetivoController.text,
                    );
                    final double inicial = _extrairValorMoeda(
                      inicialController.text,
                    );

                    if (titulo.isNotEmpty && objetivo > 0) {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);

                      final String idCliente = _getClienteId();

                      await _firestoreService.salvarMeta(
                        idCliente: idCliente,
                        titulo: titulo,
                        valorObjetivo: objetivo,
                        valorAtual: inicial,
                        categoria: categoriaSelecionada,
                      );

                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Meta financeira criada com sucesso!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'CRIAR META',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Exibe o modal para edição de uma meta financeira existente.
  void _exibirDialogoEditarMeta(Map<String, dynamic> meta) {
    final tituloController = TextEditingController(text: meta['titulo'] ?? '');
    final double objetivoOriginal =
        (meta['valor_objetivo'] as num?)?.toDouble() ?? 0.0;
    final double atualOriginal =
        (meta['valor_atual'] as num?)?.toDouble() ?? 0.0;
    final objetivoController = TextEditingController(
      text: 'R\$ ${objetivoOriginal.toStringAsFixed(2).replaceAll('.', ',')}',
    );
    final inicialController = TextEditingController(
      text: 'R\$ ${atualOriginal.toStringAsFixed(2).replaceAll('.', ',')}',
    );
    String categoriaSelecionada = meta['categoria'] ?? 'Reserva';
    final List<String> categorias = [
      'Reserva',
      'Viagem',
      'Veículo',
      'Imóvel',
      'Educação',
      'Outros',
    ];
    if (!categorias.contains(categoriaSelecionada)) {
      categorias.add(categoriaSelecionada);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text('Editar Meta Financeira'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: InputDecoration(
                        labelText: 'Nome da Meta',
                        prefixIcon: const Icon(
                          Icons.flag_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: objetivoController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _formatarMoedaEmTempoReal(val, objetivoController),
                      decoration: InputDecoration(
                        labelText: 'Valor Objetivo',
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: inicialController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) =>
                          _formatarMoedaEmTempoReal(val, inicialController),
                      decoration: InputDecoration(
                        labelText: 'Saldo Acumulado',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoriaSelecionada,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: categorias
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => categoriaSelecionada = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String titulo = tituloController.text.trim();
                    final double objetivo = _extrairValorMoeda(
                      objetivoController.text,
                    );
                    final double atual = _extrairValorMoeda(
                      inicialController.text,
                    );

                    if (titulo.isNotEmpty && objetivo > 0) {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);

                      final String idCliente = _getClienteId();
                      final String? metaId = meta['firestore_id'];

                      await _firestoreService.salvarMeta(
                        idCliente: idCliente,
                        metaId: metaId,
                        titulo: titulo,
                        valorObjetivo: objetivo,
                        valorAtual: atual,
                        categoria: categoriaSelecionada,
                      );

                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Meta financeira atualizada com sucesso!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SALVAR ALTERAÇÕES',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Formata dinamicamente o valor monetário no padrão R$ 0,00 enquanto o usuário digita.
  void _formatarMoedaEmTempoReal(
    String value,
    TextEditingController controller,
  ) {
    String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      controller.value = const TextEditingValue(
        text: 'R\$ 0,00',
        selection: TextSelection.collapsed(offset: 7),
      );
      return;
    }
    final double parsed = (double.tryParse(clean) ?? 0) / 100.0;
    final String formatted =
        'R\$ ${parsed.toStringAsFixed(2).replaceAll('.', ',')}';
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Converte a string de moeda formatada (R$ 0,00) em um número de ponto flutuante [double].
  double _extrairValorMoeda(String text) {
    final clean = text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(clean) ?? 0.0;
  }

  /// Exibe modal para aportar (adicionar dinheiro) em uma meta financeira existente.
  void _exibirDialogoAporte(Map<String, dynamic> meta) {
    final valorAporteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_card, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aportar em "${meta['titulo']}"',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo atual: R\$ ${(meta['valor_atual'] as num?)?.toStringAsFixed(2) ?? "0.00"} '
                '/ Objetivo: R\$ ${(meta['valor_objetivo'] as num?)?.toStringAsFixed(2) ?? "0.00"}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: valorAporteController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Valor a Adicionar (R\$)',
                  hintText: 'Ex: 150.00',
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: Colors.green,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double? aporte = double.tryParse(
                  valorAporteController.text.replaceAll(',', '.').trim(),
                );
                if (aporte != null && aporte > 0) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);

                  final String metaId = meta['firestore_id'] ?? '';
                  final double valorAtual =
                      (meta['valor_atual'] as num?)?.toDouble() ?? 0.0;
                  final double valorObjetivo =
                      (meta['valor_objetivo'] as num?)?.toDouble() ?? 1.0;

                  await _firestoreService.aportarMeta(
                    metaId: metaId,
                    valorAporte: aporte,
                    valorAtualAntigo: valorAtual,
                    valorObjetivo: valorObjetivo,
                  );

                  if (mounted) {
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Aporte de R\$ ${aporte.toStringAsFixed(2)} adicionado com sucesso!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ADICIONAR DINHEIRO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Retorna a cor de semáforo com base no percentual atingido da meta.
  /// - Menos de 34%: Vermelho
  /// - Entre 34% e 66%: Amarelo/Laranja
  /// - A partir de 67%: Verde
  Color _getCorSemaforo(double percentual) {
    if (percentual < 0.34) {
      return const Color(0xFFE53935); // Vermelho
    } else if (percentual < 0.67) {
      return const Color(0xFFFB8C00); // Amarelo/Laranja
    } else {
      return const Color(0xFF4CAF50); // Verde
    }
  }

  @override
  Widget build(BuildContext context) {
    final String idCliente = _getClienteId();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
      child: Scaffold(
        backgroundColor: AppColors.getBackgroundColor(context),
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: const Text(
            'Metas Financeiras',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryYellow,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.hourglass_top_outlined, size: 20),
                text: 'Em Andamento',
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline, size: 20),
                text: 'Concluídas',
              ),
            ],
          ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.buscarMetasStream(idCliente),
          builder: (context, snapshot) {
            final List<Map<String, dynamic>> todasMetas = snapshot.data ?? [];

            // Calcula estatísticas gerais de progresso total de todas as metas
            double totalAtual = 0;
            double totalObjetivo = 0;

            for (final m in todasMetas) {
              totalAtual += (m['valor_atual'] as num?)?.toDouble() ?? 0.0;
              totalObjetivo += (m['valor_objetivo'] as num?)?.toDouble() ?? 0.0;
            }

            final double progressoGeral = totalObjetivo > 0
                ? (totalAtual / totalObjetivo).clamp(0.0, 1.0)
                : 0.0;

            final metasEmAndamento = todasMetas
                .where((m) => (m['concluida'] != true))
                .toList();
            final metasConcluidas = todasMetas
                .where((m) => (m['concluida'] == true))
                .toList();

            return Column(
              children: [
                // 1. Card de Progresso Total de Todas as Metas
                _buildHeaderProgressoTotal(
                  totalAtual,
                  totalObjetivo,
                  progressoGeral,
                ),

                // 2. Lista de Metas filtradas por aba ("Em Andamento" vs "Concluídas")
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListaMetas(metasEmAndamento, isConcluidas: false),
                      _buildListaMetas(metasConcluidas, isConcluidas: true),
                    ],
                  ),
                ),

                // 3. Dica Inteligente no Rodapé
                _buildDicaInteligenteFooter(),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: exibirDialogoNovaMeta,
          backgroundColor: AppColors.getPrimaryAccent(context),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Nova Meta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// Constrói o card superior com a síntese do progresso financeiro acumulado.
  Widget _buildHeaderProgressoTotal(
    double atual,
    double objetivo,
    double progresso,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso Total das Caixinhas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getCorSemaforo(progresso).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progresso * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getCorSemaforo(progresso),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              color: _getCorSemaforo(progresso),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Acumulado: R\$ ${atual.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Objetivo: R\$ ${objetivo.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói a lista deslizável de caixinhas ou o estado vazio convidativo.
  Widget _buildListaMetas(
    List<Map<String, dynamic>> metas, {
    required bool isConcluidas,
  }) {
    if (metas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isConcluidas
                    ? Icons.emoji_events_outlined
                    : Icons.savings_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                isConcluidas
                    ? 'Nenhuma meta concluída ainda.'
                    : 'Você ainda não possui metas em andamento.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isConcluidas
                    ? 'Continue guardando economias para atingir seus objetivos!'
                    : 'Clique no botão "+" para criar sua primeira caixinha de investimentos!',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: metas.length,
      itemBuilder: (context, index) {
        final m = metas[index];
        final double atual = (m['valor_atual'] as num?)?.toDouble() ?? 0.0;
        final double objetivo =
            (m['valor_objetivo'] as num?)?.toDouble() ?? 1.0;
        final double progresso = (atual / objetivo).clamp(0.0, 1.0);
        final Color corProgresso = _getCorSemaforo(progresso);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: corProgresso.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: corProgresso.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.savings_outlined,
                            color: corProgresso,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['titulo'] ?? 'Sem Título',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                m['categoria'] ?? 'Geral',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu de Ações (Editar e Excluir)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        tooltip: 'Editar Meta',
                        onPressed: () => _exibirDialogoEditarMeta(m),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                        tooltip: 'Excluir Meta',
                        onPressed: () async {
                          final String metaId = m['firestore_id'] ?? '';
                          if (metaId.isNotEmpty) {
                            await _firestoreService.excluirMeta(metaId);
                            if (context.mounted) {
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Barra de Progresso em Cores de Semáforo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: corProgresso,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SALDO ACUMULADO',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'R\$ ${atual.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: corProgresso,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'META FINAL',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'R\$ ${objetivo.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (!isConcluidas) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _exibirDialogoAporte(m),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Adicionar Dinheiro à Caixinha'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.getPrimaryAccent(context),
                      side: BorderSide(
                        color: AppColors.getPrimaryAccent(context),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Constrói o rodapé com a dica inteligente de economia.
  Widget _buildDicaInteligenteFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber.shade800, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Dica Inteligente COGITO: Guardar pequenos aportes semanais de forma constante é 3x mais eficaz do que fazer grandes depósitos esporádicos!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
