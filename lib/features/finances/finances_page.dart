import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/utils/financial_utils.dart';
import 'package:cogito/features/finances/detailed_analysis_page.dart';
import 'package:cogito/features/finances/financial_goals_page.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela principal de Finanças do COGITO.
/// Estruturada com abas principais para "Extrato" e "Orçamentos".
class FinancesPage extends StatefulWidget {
  const FinancesPage({super.key});

  @override
  FinancesPageState createState() => FinancesPageState();
}

/// Estado público para permitir que a HomePage acione ações da página de Finanças.
class FinancesPageState extends State<FinancesPage> {
  /// Controller da aba principal (0: Extrato, 1: Orçamentos).
  int _mainTabIndex = 0;

  /// Retorna o índice da aba principal ativa.
  int get mainTabIndex => _mainTabIndex;

  /// Permite selecionar a aba principal programaticamente.
  void selecionarAba(int index) {
    if (mounted) {
      setState(() {
        _mainTabIndex = index;
      });
    }
  }

  /// Permite selecionar a aba de extrato programaticamente.
  void selecionarAbaExtrato() => selecionarAba(0);

  /// Permite selecionar a aba de orçamentos programaticamente.
  void selecionarAbaOrcamentos() => selecionarAba(1);

  /// Permite selecionar a aba do modo freelancer programaticamente.
  void selecionarAbaFreelancer() => selecionarAba(2);

  /// Permite navegar para a página de metas financeiras.
  void selecionarAbaMetas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MetasFinanceirasPage()),
    );
  }

  /// Instância do serviço Firebase Firestore.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Controller para o campo de busca de transações.
  final TextEditingController _searchController = TextEditingController();

  /// Filtro de categoria selecionado ("Todas as categorias" por padrão).
  String _selectedCategoryFilter = 'Todas as categorias';

  /// Filtro de período selecionado ("Este mês" por padrão).
  String _selectedPeriodoFilter = 'Este mês';

  /// Modo de visualização do extrato ('list': Lista, 'grid': Grade, 'table': Tabela).
  String _viewMode = 'list';

  /// Extrai com segurança a data [DateTime] de uma transação via [FinancialUtils].
  DateTime _extrairData(Map<String, dynamic> t) =>
      FinancialUtils.extrairDataTransacao(t);

  /// Filtra a lista de transações conforme o período selecionado via [FinancialUtils].
  List<Map<String, dynamic>> _filtrarTransacoesPorPeriodo(
    List<Map<String, dynamic>> lista,
  ) {
    return FinancialUtils.filtrarTransacoesPorPeriodo(
      lista,
      _selectedPeriodoFilter,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Exibe o modal para criação de uma nova transação (Receita ou Despesa).
  /// Método público acessível globalmente via [financasPageKey].
  void exibirDialogoNovaTransacao() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String categoria = 'Alimentação';
    String tipo = 'Despesa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Alça visual do modal
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Text(
                    'Nova Transação',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seleção de Tipo (Despesa / Receita)
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Despesa',
                        label: Text('Despesa'),
                        icon: Icon(Icons.arrow_downward, color: Colors.red),
                      ),
                      ButtonSegment(
                        value: 'Receita',
                        label: Text('Receita'),
                        icon: Icon(Icons.arrow_upward, color: Colors.green),
                      ),
                    ],
                    selected: {tipo},
                    onSelectionChanged: (val) {
                      setModalState(() {
                        tipo = val.first;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Descrição da Transação
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Descrição (Ex: iFood - Almoço)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Valor em Reais
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Valor (R\$)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Seleção de Categoria
                  DropdownButtonFormField<String>(
                    initialValue: categoria,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items:
                        [
                              'Alimentação',
                              'Moradia',
                              'Transporte',
                              'Lazer',
                              'Receita',
                              'Outros',
                            ]
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          categoria = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Botão para salvar transação no Firestore
                  ElevatedButton(
                    onPressed: () async {
                      final val =
                          double.tryParse(
                            amountController.text.replaceAll(',', '.'),
                          ) ??
                          0.0;
                      if (titleController.text.trim().isNotEmpty && val > 0) {
                        final String uid =
                            FirebaseFirestoreService.idClienteAtual;

                        await _firestoreService.adicionarTransacao(
                          idCliente: uid,
                          titulo: titleController.text.trim(),
                          valor: val,
                          categoria: categoria,
                          tipo: tipo,
                          data: DateTime.now(),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text('Transação salva com sucesso!'),
                                ],
                              ),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Preencha todos os campos corretamente.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'SALVAR TRANSAÇÃO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Configura a barra de status e estrutura o layout da tela com cabeçalho e abas
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.statusBarStyle,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Column(
          children: [
            // Cabeçalho da Tela com Abas Principais (Extrato, Orçamentos e Freelancer)
            _buildHeader(context),

            // Conteúdo principal alternado pelas abas
            Expanded(
              child: _mainTabIndex == 0
                  ? _buildExtratoSection()
                  : (_mainTabIndex == 1
                        ? _buildOrcamentosSection()
                        : _buildFreelancerSection()),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho superior azul com bordas retas e botões das abas principais no estilo TabBar.
  Widget _buildHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 6),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius:
            BorderRadius.zero, // Reto, não arredondado conforme solicitado
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestão Financeira',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  if (_mainTabIndex == 1) {
                    _exibirDialogoNovoOrcamento();
                  } else if (_mainTabIndex == 2) {
                    _exibirDialogoNovoJobFreelancer();
                  } else {
                    exibirDialogoNovaTransacao();
                  }
                },
                tooltip: _mainTabIndex == 1
                    ? 'Novo Orçamento'
                    : (_mainTabIndex == 2 ? 'Novo Job' : 'Nova Transação'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Seletor de Abas Principais: Extrato, Orçamentos e Freelancer com ícones e sublinhado amarelo reto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildMainTabButton(
                  titulo: 'Extrato',
                  icon: Icons.receipt_long_outlined,
                  index: 0,
                ),
              ),
              Expanded(
                child: _buildMainTabButton(
                  titulo: 'Orçamentos',
                  icon: Icons.pie_chart_outline,
                  index: 1,
                ),
              ),
              Expanded(
                child: _buildMainTabButton(
                  titulo: 'Freelancer',
                  icon: Icons.work_outline,
                  index: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói o botão individual da aba principal com ícone, texto e sublinhado amarelo reto (não arredondado).
  Widget _buildMainTabButton({
    required String titulo,
    required IconData icon,
    required int index,
  }) {
    final bool isSelected = _mainTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mainTabIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? Colors.white : Colors.white70,
          ),
          const SizedBox(height: 6),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          // Indicador sublinhado amarelo reto em destaque para a aba ativa
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isSelected ? 60 : 0,
            decoration: const BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.zero, // Reto, não arredondado
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói a seção de EXTRATO de transações com atalho direto para a Análise de Gastos.
  Widget _buildExtratoSection() {
    return _buildTransacoesSection();
  }

  /// Constrói a aba de TRANSAÇÕES inteiramente conectada ao Firestore em tempo real.
  Widget _buildTransacoesSection() {
    final String uid = FirebaseFirestoreService.idClienteAtual;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.ouvirTransacoes(uid),
      builder: (context, snapshot) {
        final rawTransacoes = snapshot.data ?? [];

        // Aplica o filtro de período ativo antes de calcular os totais
        final List<Map<String, dynamic>> transacoesNoPeriodo =
            _filtrarTransacoesPorPeriodo(rawTransacoes);

        // Cálculo dinâmico das totais de Receitas e Despesas baseado no período selecionado
        double totalReceitas = 0.0;
        double totalDespesas = 0.0;

        for (final t in transacoesNoPeriodo) {
          final double val = (t['valor'] as num?)?.toDouble() ?? 0.0;
          if (t['tipo'] == 'Receita') {
            totalReceitas += val;
          } else {
            totalDespesas += val;
          }
        }

        // Filtragem adicional por busca de texto e categoria
        List<Map<String, dynamic>> transacoesFiltradas = List.from(
          transacoesNoPeriodo,
        );

        if (_searchController.text.trim().isNotEmpty) {
          final query = _searchController.text.trim().toLowerCase();
          transacoesFiltradas = transacoesFiltradas.where((t) {
            final titulo = (t['titulo'] ?? '').toString().toLowerCase();
            final cat = (t['categoria'] ?? '').toString().toLowerCase();
            return titulo.contains(query) || cat.contains(query);
          }).toList();
        }

        if (_selectedCategoryFilter != 'Todas as categorias') {
          transacoesFiltradas = transacoesFiltradas.where((t) {
            return t['categoria'] == _selectedCategoryFilter;
          }).toList();
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            // 1. Cards de Resumo Superior (Receitas e Despesas filtradas por período)
            Row(
              children: [
                Expanded(
                  child: _buildResumoHeaderCard(
                    titulo: 'Receitas ($_selectedPeriodoFilter)',
                    valor: totalReceitas,
                    isReceita: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResumoHeaderCard(
                    titulo: 'Despesas ($_selectedPeriodoFilter)',
                    valor: totalDespesas,
                    isReceita: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. Barra de Busca e Filtros de Categoria e Período
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Campo "Buscar transação..."
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar transação...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF2F4F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Linha com Seletores Dropdown de Categoria e Período (com isExpanded para evitar overflow)
                  Row(
                    children: [
                      // Seletor de Categoria
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategoryFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF2F4F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items:
                              [
                                    'Todas as categorias',
                                    'Alimentação',
                                    'Moradia',
                                    'Transporte',
                                    'Lazer',
                                    'Receita',
                                    'Outros',
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategoryFilter = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Seletor de Período
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPeriodoFilter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF2F4F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items:
                              [
                                    'Este mês',
                                    'Últimos 30 dias',
                                    'Últimos 3 meses',
                                    'Este ano',
                                    'Todo o período',
                                  ]
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        p,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPeriodoFilter = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Barra de Botões Rápidos em Pílula (Orçamentos, Metas, Exportar, Análise)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionPill(
                    label: 'Orçamentos',
                    icon: Icons.pie_chart_outline,
                    onTap: () => setState(() => _mainTabIndex = 1),
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    label: 'Metas',
                    icon: Icons.flag_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MetasFinanceirasPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    label: 'Exportar',
                    icon: Icons.file_download_outlined,
                    onTap: () =>
                        _exibirModalExportar(context, transacoesFiltradas),
                  ),
                  const SizedBox(width: 8),
                  _buildActionPill(
                    label: 'Análise',
                    icon: Icons.bar_chart_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnaliseDetalhadaPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Cabeçalho da Lista ("Todas", Botões de Lista/Grade/Tabela)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transações (${transacoesFiltradas.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Row(
                  children: [
                    // Botões de alternância Lista / Grade / Tabela
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.view_list_rounded,
                              size: 20,
                              color: _viewMode == 'list'
                                  ? AppColors.primaryBlue
                                  : Colors.grey,
                            ),
                            onPressed: () => setState(() => _viewMode = 'list'),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Visualizar em Lista',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.grid_view_rounded,
                              size: 20,
                              color: _viewMode == 'grid'
                                  ? AppColors.primaryBlue
                                  : Colors.grey,
                            ),
                            onPressed: () => setState(() => _viewMode = 'grid'),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Visualizar em Grade',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.table_chart_outlined,
                              size: 20,
                              color: _viewMode == 'table'
                                  ? AppColors.primaryBlue
                                  : Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => _viewMode = 'table'),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            padding: EdgeInsets.zero,
                            tooltip: 'Visualizar em Tabela',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Botão "Exportar" em Laranja
                    InkWell(
                      onTap: () =>
                          _exibirModalExportar(context, transacoesFiltradas),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.file_download_outlined,
                            color: AppColors.primaryOrange,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Exportar',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 12),

            // 5. Lista de Transações (Lista, Grade ou Tabela)
            if (transacoesFiltradas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Nenhuma transação encontrada.',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else if (_viewMode == 'table')
              _buildTableView(transacoesFiltradas)
            else if (_viewMode == 'grid')
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: transacoesFiltradas.length,
                itemBuilder: (context, index) {
                  final t = transacoesFiltradas[index];
                  return _buildGridTransactionCard(t);
                },
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transacoesFiltradas.length,
                itemBuilder: (context, index) {
                  final t = transacoesFiltradas[index];
                  final String firestoreId = t['firestore_id'] ?? '';

                  return Dismissible(
                    key: Key(
                      firestoreId.isEmpty ? index.toString() : firestoreId,
                    ),
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Deslizar para a DIREITA -> Editar Transação
                        _exibirDialogoEditarTransacao(t);
                        return false;
                      } else {
                        // Deslizar para a ESQUERDA -> Confirmar Exclusão
                        return true;
                      }
                    },
                    onDismissed: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        if (firestoreId.isNotEmpty &&
                            !firestoreId.startsWith('mock_')) {
                          await _firestoreService.excluirTransacao(firestoreId);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Transação excluída.'),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Excluir',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.delete, color: Colors.white),
                        ],
                      ),
                    ),
                    child: _buildListTransactionCard(t),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  /// Exibe caixa de diálogo para edição dos dados de uma transação existente.
  ///
  /// Parâmetros:
  /// - [transacao]: Mapa contendo os dados atuais da transação a ser editada.
  void _exibirDialogoEditarTransacao(Map<String, dynamic> transacao) {
    final tituloController = TextEditingController(
      text: transacao['titulo'] ?? '',
    );
    final valorController = TextEditingController(
      text: (transacao['valor'] as num?)?.toStringAsFixed(2) ?? '',
    );
    String categoriaSelecionada = transacao['categoria'] ?? 'Alimentação';
    String tipoSelecionado = transacao['tipo'] ?? 'Despesa';

    final categorias = [
      'Alimentação',
      'Moradia',
      'Transporte',
      'Lazer',
      'Receita',
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
                  Icon(Icons.edit_note_rounded, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text('Editar Transação'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: InputDecoration(
                        labelText: 'Descrição / Título',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valorController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Valor (R\$)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categorias.contains(categoriaSelecionada)
                          ? categoriaSelecionada
                          : 'Outros',
                      decoration: InputDecoration(
                        labelText: 'Categoria',
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tipoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Receita',
                          child: Text('Receita (+)'),
                        ),
                        DropdownMenuItem(
                          value: 'Despesa',
                          child: Text('Despesa (-)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null)
                          setModalState(() => tipoSelecionado = val);
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
                    final String novoTitulo = tituloController.text.trim();
                    final double? novoValor = double.tryParse(
                      valorController.text.replaceAll(',', '.').trim(),
                    );

                    if (novoTitulo.isNotEmpty && novoValor != null) {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      final String firestoreId =
                          (transacao['firestore_id'] ?? '').toString();
                      if (firestoreId.isNotEmpty &&
                          !firestoreId.startsWith('mock_')) {
                        await _firestoreService.atualizarTransacao(
                          transacaoId: firestoreId,
                          titulo: novoTitulo,
                          valor: novoValor,
                          categoria: categoriaSelecionada,
                          tipo: tipoSelecionado,
                        );
                      }
                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Transação atualizada com sucesso!'),
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
                    'Salvar Alterações',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Exibe o modal para exportação real do extrato financeiro nos formatos CSV, PDF/Texto, TXT e JSON.
  void _exibirModalExportar(
    BuildContext context, [
    List<Map<String, dynamic>>? listaTransacoes,
  ]) {
    final List<Map<String, dynamic>> transacoes =
        listaTransacoes ?? _firestoreService.cacheTransacoesLocal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'Exportar Extrato Financeiro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Exportando ${transacoes.length} lançamentos ($_selectedPeriodoFilter):',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(
                  Icons.table_view_outlined,
                  color: Colors.green,
                  size: 28,
                ),
                title: const Text(
                  'Microsoft Excel / Google Planilhas (.CSV)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Estrutura de colunas com Data, Categoria, Título e Valor',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _gerarEProcessarExportacao(
                    'CSV',
                    _gerarConteudoCSV(transacoes),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Colors.red,
                  size: 28,
                ),
                title: const Text(
                  'Relatório Financeiro Formatado (.PDF / Texto)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Relatório executivo estruturado com balanço e envelopes',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _gerarEProcessarExportacao(
                    'PDF / Relatório Formatado',
                    _gerarConteudoRelatorio(transacoes),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: Colors.blue,
                  size: 28,
                ),
                title: const Text(
                  'Texto Simples (.TXT)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Extrato limpo para anotações e compartilhamento rápido',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _gerarEProcessarExportacao(
                    'TXT',
                    _gerarConteudoTXT(transacoes),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.code_outlined,
                  color: Colors.purple,
                  size: 28,
                ),
                title: const Text(
                  'Dados Estruturados (.JSON)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'JSON válido com metadados para desenvolvedores e integrações',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _gerarEProcessarExportacao(
                    'JSON',
                    _gerarConteudoJSON(transacoes),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Gera string no formato CSV a partir da lista de transações via [FinancialUtils].
  String _gerarConteudoCSV(List<Map<String, dynamic>> transacoes) {
    return FinancialUtils.gerarExtratoCSV(transacoes);
  }

  /// Gera relatório executivo detalhado em formato de texto via [FinancialUtils].
  String _gerarConteudoRelatorio(List<Map<String, dynamic>> transacoes) {
    return FinancialUtils.gerarRelatorioExecutivo(
      transacoes,
      _selectedPeriodoFilter,
    );
  }

  /// Gera arquivo de texto simples para cópia rápida.
  String _gerarConteudoTXT(List<Map<String, dynamic>> transacoes) {
    final buffer = StringBuffer();
    buffer.writeln('EXTRATO COGITO - $_selectedPeriodoFilter');
    for (final t in transacoes) {
      final dt = _extrairData(t);
      final dataStr =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
      final val = ((t['valor'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2);
      buffer.writeln(
        '$dataStr - ${t['titulo']} (${t['categoria']}): R\$ $val [${t['tipo']}]',
      );
    }
    return buffer.toString();
  }

  /// Gera estrutura JSON formatada via [FinancialUtils].
  String _gerarConteudoJSON(List<Map<String, dynamic>> transacoes) {
    return FinancialUtils.gerarExtratoJSON(transacoes, _selectedPeriodoFilter);
  }

  /// Copia o conteúdo para a área de transferência e abre modal de pré-visualização e confirmação.
  void _gerarEProcessarExportacao(String formato, String conteudo) {
    Clipboard.setData(ClipboardData(text: conteudo));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exportação Gerada ($formato)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'O conteúdo foi copiado para a Área de Transferência com sucesso. Você pode colar onde desejar ou visualizar o conteúdo abaixo:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  conteudo,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: conteudo));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Conteúdo do $formato copiado novamente!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.white, size: 18),
              label: const Text(
                'Copiar Novamente',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói a visualização do extrato em formato de Tabela de Dados (DataTable).
  Widget _buildTableView(List<Map<String, dynamic>> transacoes) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primaryBlue.withValues(alpha: 0.1),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'Data',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Categoria',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Descrição',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Tipo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Valor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Ações',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
          rows: transacoes.map((t) {
            final DateTime dt = t['data_dt'] ?? DateTime.now();
            final String dataStr =
                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
            final bool isReceita = t['tipo'] == 'Receita';
            final double val = (t['valor'] as num?)?.toDouble() ?? 0.0;

            return DataRow(
              cells: [
                DataCell(Text(dataStr, style: const TextStyle(fontSize: 12))),
                DataCell(
                  Text(
                    t['categoria'] ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    t['titulo'] ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isReceita
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isReceita ? 'Receita' : 'Despesa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isReceita ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${isReceita ? '+' : '-'} R\$ ${val.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isReceita ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: () => _exibirDialogoEditarTransacao(t),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          final String firestoreId = t['firestore_id'] ?? '';
                          if (firestoreId.isNotEmpty &&
                              !firestoreId.startsWith('mock_')) {
                            await _firestoreService.excluirTransacao(
                              firestoreId,
                            );
                          }
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Constrói o card de resumo de topo (Receitas ou Despesas) com padrão visual limpo e predominância do azul.
  Widget _buildResumoHeaderCard({
    required String titulo,
    required double valor,
    required bool isReceita,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isReceita
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFF0F4FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isReceita
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: isReceita
                      ? const Color(0xFF1976D2)
                      : AppColors.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              color: isReceita
                  ? const Color(0xFF1976D2)
                  : AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói botões de ação rápida em formato de pílula em estilo minimalista azul e limpo.
  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6E4F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói cada card de transação na lista com design simples, limpo e em tons de azul.
  Widget _buildListTransactionCard(Map<String, dynamic> t) {
    final String titulo = t['titulo'] ?? 'Transação';
    final bool isDespesa = t['tipo'] == 'Despesa';
    final double valor = (t['valor'] as num?)?.toDouble() ?? 0.0;
    final String categoria = t['categoria'] ?? 'Outros';
    final DateTime data = t['data_dt'] as DateTime? ?? DateTime.now();

    // Formatação amigável da data ("Hoje", "Ontem" ou "02 de ago.")
    final String dataStr = _formatarDataAmigavel(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Ícone em container azul suave uniforme
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _obterIconeCategoria(categoria),
              color: AppColors.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Título e Categoria • Data
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$categoria  •  $dataStr',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),

          // Valor em destaque
          Text(
            '${isDespesa ? "- " : "+ "}R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              color: isDespesa
                  ? AppColors.primaryBlue
                  : const Color(0xFF1976D2),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o card individual quando exibido no modo Grade com padrão azul.
  Widget _buildGridTransactionCard(Map<String, dynamic> t) {
    final String titulo = t['titulo'] ?? 'Transação';
    final bool isDespesa = t['tipo'] == 'Despesa';
    final double valor = (t['valor'] as num?)?.toDouble() ?? 0.0;
    final String categoria = t['categoria'] ?? 'Outros';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF2F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _obterIconeCategoria(categoria),
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.primaryBlue,
            ),
          ),
          Text(
            '${isDespesa ? "- " : "+ "}R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              color: isDespesa
                  ? AppColors.primaryBlue
                  : const Color(0xFF1976D2),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Formata a data para exibir "Hoje", "Ontem" ou a data amigável.
  String _formatarDataAmigavel(DateTime dt) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dataTrans = DateTime(dt.year, dt.month, dt.day);

    if (dataTrans == hoje) return 'Hoje';
    if (dataTrans == hoje.subtract(const Duration(days: 1))) return 'Ontem';

    final meses = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return '${dt.day.toString().padLeft(2, '0')} de ${meses[dt.month - 1]}.';
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

  /// Converte o texto no formato R$ 0,00 para valor numérico double.
  double _extrairValorMoeda(String text) {
    final clean = text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(clean) ?? 0.0;
  }

  /// Exibe o modal para criação ou edição de um Orçamento por categoria com o design solicitado.
  void _exibirDialogoNovoOrcamento({Map<String, dynamic>? orcamentoExistente}) {
    String categoriaSelecionada =
        orcamentoExistente?['categoria'] ?? 'Alimentação';
    final double limiteOriginal =
        (orcamentoExistente?['limite'] as num?)?.toDouble() ?? 0.0;
    final limiteController = TextEditingController(
      text: limiteOriginal > 0
          ? 'R\$ ${limiteOriginal.toStringAsFixed(2).replaceAll('.', ',')}'
          : 'R\$ 0,00',
    );

    final List<Map<String, dynamic>> opcoesCategorias = [
      {'nome': 'Alimentação', 'icon': Icons.fastfood_outlined},
      {'nome': 'Transporte', 'icon': Icons.directions_car_outlined},
      {'nome': 'Lazer', 'icon': Icons.sports_esports_outlined},
      {'nome': 'Saúde', 'icon': Icons.medical_services_outlined},
      {'nome': 'Educação', 'icon': Icons.school_outlined},
      {'nome': 'Moradia', 'icon': Icons.home_outlined},
      {'nome': 'Compras', 'icon': Icons.shopping_bag_outlined},
      {'nome': 'Outros', 'icon': Icons.inventory_2_outlined},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do Modal: Título e Botão Fechar 'x'
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          orcamentoExistente != null
                              ? 'Editar Orçamento'
                              : 'Novo Orçamento',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Label Categoria
                    const Text(
                      'Categoria',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Grid de 8 Categorias usando os ícones do aplicativo
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: opcoesCategorias.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.15,
                          ),
                      itemBuilder: (context, index) {
                        final cat = opcoesCategorias[index];
                        final String nome = cat['nome'];
                        final IconData icone = cat['icon'];
                        final bool isSelecionado = categoriaSelecionada == nome;

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              categoriaSelecionada = nome;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelecionado
                                  ? AppColors.primaryOrange.withValues(
                                      alpha: 0.08,
                                    )
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelecionado
                                    ? AppColors.primaryOrange
                                    : Colors.grey.shade200,
                                width: isSelecionado ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icone,
                                  size: 24,
                                  color: isSelecionado
                                      ? AppColors.primaryOrange
                                      : AppColors.primaryBlue,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  nome,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelecionado
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelecionado
                                        ? AppColors.primaryOrange
                                        : Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // Label Limite Mensal
                    const Text(
                      'Limite Mensal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input formatado automaticamente em R$
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: limiteController,
                        keyboardType: TextInputType.number,
                        onChanged: (val) =>
                            _formatarMoedaEmTempoReal(val, limiteController),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Box Informativo (estilo alerta suave com ícone track_changes)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCCE0FF)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.track_changes_outlined,
                            color: Color(0xFF1976D2),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Defina um limite mensal para esta categoria. Você receberá alertas quando atingir 75% do orçamento.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1565C0),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botões Cancelar e Salvar Orçamento
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final double limite = _extrairValorMoeda(
                                limiteController.text,
                              );
                              if (limite <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Por favor, informe um limite mensal maior que R\$ 0,00.',
                                    ),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final String idCliente =
                                  FirebaseFirestoreService.idClienteAtual;
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(modalCtx);

                              await _firestoreService.salvarOrcamento(
                                idCliente: idCliente,
                                categoria: categoriaSelecionada,
                                limite: limite,
                              );

                              if (mounted) {
                                setState(() {});
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Orçamento de $categoriaSelecionada salvo com sucesso!',
                                    ),
                                    backgroundColor: AppColors.primaryBlue,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Salvar Orçamento',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Constrói a aba de Orçamentos conectada em tempo real com o Cloud Firestore,
  /// com cálculo reativo dos gastos a partir das transações cadastradas,
  /// e suporte a arrastar para a direita (editar) e arrastar para a esquerda (deletar).
  Widget _buildOrcamentosSection() {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;
    final DateTime agora = DateTime.now();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.buscarOrcamentosStream(idCliente),
      builder: (context, snapshotOrcamentos) {
        // Previne o "piscar" da tela aguardando a primeira emissão de dados
        if (snapshotOrcamentos.connectionState == ConnectionState.waiting &&
            !snapshotOrcamentos.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }

        final List<Map<String, dynamic>> orcamentosFirestore =
            snapshotOrcamentos.data ?? [];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.buscarTransacoesStream(idCliente),
          builder: (context, snapshotTransacoes) {
            final List<Map<String, dynamic>> transacoes =
                snapshotTransacoes.data ?? [];

            // Calcula o total gasto no mês corrente para cada categoria a partir das transações reais
            final Map<String, double> gastosPorCategoria = {};
            for (final t in transacoes) {
              final String tipo = t['tipo'] ?? 'Despesa';
              if (tipo == 'Despesa') {
                final DateTime dt = FinancialUtils.extrairDataTransacao(t);
                if (dt.year == agora.year && dt.month == agora.month) {
                  final String cat = t['categoria'] ?? 'Outros';
                  final double val = (t['valor'] as num?)?.toDouble() ?? 0.0;
                  gastosPorCategoria[cat] =
                      (gastosPorCategoria[cat] ?? 0.0) + val;
                }
              }
            }

            // Lista consolidada de orçamentos (apenas dados reais salvos no Firestore)
            final List<Map<String, dynamic>> listaExibicao = orcamentosFirestore
                .map((orc) {
                  final String cat = orc['categoria'] ?? 'Outros';
                  final double limite =
                      (orc['limite'] as num?)?.toDouble() ?? 0.0;
                  final double gasto = gastosPorCategoria[cat] ?? 0.0;
                  return {
                    'categoria': cat,
                    'limite': limite,
                    'gasto': gasto,
                    'cor': _obterCorCategoria(cat),
                    'id': orc['id'] ?? cat,
                  };
                })
                .toList();

            // Estado vazio quando não houver orçamentos cadastrados pelo usuário
            if (listaExibicao.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDF2F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pie_chart_outline_rounded,
                          size: 48,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nenhum orçamento cadastrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Defina limites mensais para suas categorias e acompanhe seus gastos em tempo real.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _exibirDialogoNovoOrcamento(),
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Novo Orçamento',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            double totalLimite = 0.0;
            double totalGasto = 0.0;
            for (final item in listaExibicao) {
              totalLimite += (item['limite'] as num).toDouble();
              totalGasto += (item['gasto'] as num).toDouble();
            }

            final double pctGeral = totalLimite > 0
                ? (totalGasto / totalLimite).clamp(0.0, 1.0)
                : 0.0;
            final double saldoRestanteGeral = totalLimite - totalGasto;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Banner Superior de Resumo dos Orçamentos (Cor sólida sem degradê)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.25),
                        blurRadius: 12,
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
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Orçado no Mês',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Resumo de Envelopes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${(pctGeral * 100).toStringAsFixed(0)}% Usado',
                              style: const TextStyle(
                                color: AppColors.primaryYellow,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Barra de Progresso Geral
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: pctGeral,
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pctGeral > 0.85
                                ? Colors.redAccent
                                : AppColors.primaryYellow,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gasto Total',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'R\$ ${totalGasto.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Restante Livre',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'R\$ ${saldoRestanteGeral.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Cabeçalho dos Envelopes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Envelopes de Categorias',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primaryOrange,
                        size: 24,
                      ),
                      onPressed: () => _exibirDialogoNovoOrcamento(),
                      tooltip: 'Novo Orçamento',
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Dica sutil de gestos
                Text(
                  '💡 Dica: Arraste para a direita para editar ou para a esquerda para excluir',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),

                const SizedBox(height: 10),

                // 2. Envelopes Individuais com Dismissible (Arrastar para a direita edita, para a esquerda deleta)
                ...listaExibicao.map((item) {
                  final String cat = item['categoria'];
                  final double gasto = (item['gasto'] as num).toDouble();
                  final double limite = (item['limite'] as num).toDouble();
                  final Color cor = item['cor'] as Color;
                  final double pct = limite > 0
                      ? (gasto / limite).clamp(0.0, 1.0)
                      : 0.0;
                  final double restante = limite - gasto;
                  final bool isAlerta = pct >= 0.8;

                  return Dismissible(
                    key: Key('orcamento_${cat}_${item['id']}'),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Excluir',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Arrastar para a direita: Edita o orçamento
                        _exibirDialogoNovoOrcamento(orcamentoExistente: item);
                        return false;
                      } else {
                        // Arrastar para a esquerda: Deleta o orçamento
                        final messenger = ScaffoldMessenger.of(context);
                        final bool? confirmar = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir Orçamento'),
                              ],
                            ),
                            content: Text(
                              'Deseja realmente remover o orçamento da categoria "$cat"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Excluir',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmar == true) {
                          await _firestoreService.excluirOrcamento(
                            idCliente: idCliente,
                            categoria: cat,
                          );
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Orçamento de $cat excluído.'),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          return true;
                        }
                        return false;
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isAlerta
                              ? Colors.red.shade300
                              : Colors.grey.shade200,
                          width: isAlerta ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _obterIconeCategoria(cat),
                                      color: cor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${(pct * 100).toStringAsFixed(0)}% utilizado',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'R\$ ${gasto.toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isAlerta
                                          ? Colors.red.shade600
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'de R\$ ${limite.toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Barra de Progresso
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAlerta ? Colors.red.shade500 : cor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isAlerta)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Atenção aos gastos!',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  restante >= 0
                                      ? 'Disponível: R\$ ${restante.toStringAsFixed(2).replaceAll('.', ',')}'
                                      : 'Excedido em: R\$ ${(-restante).toStringAsFixed(2).replaceAll('.', ',')}',
                                  style: TextStyle(
                                    color: restante >= 0
                                        ? Colors.green.shade700
                                        : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _exibirDialogoNovoOrcamento(
                                  orcamentoExistente: item,
                                ),
                                tooltip: 'Editar',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  /// Retorna o ícone temático adequado para cada envelope de orçamento utilizando os ícones do app.
  IconData _obterIconeCategoria(String cat) {
    switch (cat) {
      case 'Alimentação':
        return Icons.fastfood_outlined;
      case 'Transporte':
        return Icons.directions_car_outlined;
      case 'Lazer':
        return Icons.sports_esports_outlined;
      case 'Saúde':
        return Icons.medical_services_outlined;
      case 'Educação':
        return Icons.school_outlined;
      case 'Moradia':
        return Icons.home_outlined;
      case 'Compras':
        return Icons.shopping_bag_outlined;
      case 'Outros':
      default:
        return Icons.inventory_2_outlined;
    }
  }

  /// Retorna a cor temática para cada categoria.
  Color _obterCorCategoria(String cat) {
    switch (cat) {
      case 'Alimentação':
        return Colors.orange;
      case 'Transporte':
        return Colors.blue;
      case 'Lazer':
        return Colors.purple;
      case 'Saúde':
        return Colors.redAccent;
      case 'Educação':
        return Colors.indigo;
      case 'Moradia':
        return Colors.teal;
      case 'Compras':
        return Colors.pink;
      case 'Outros':
      default:
        return Colors.grey.shade600;
    }
  }

  /// Constrói a aba completa do Modo Freelancer para autônomos e prestadores de serviços.
  /// Inclui controle de faturamento, reserva de oscilação, simulador de hora e lista de jobs conectados ao Firestore.
  Widget _buildFreelancerSection() {
    final String uid = FirebaseFirestoreService.idClienteAtual;
    final DateTime agora = DateTime.now();
    final usuario = FirebaseFirestoreService.usuarioLogado;
    final double metaMensal =
        (usuario?['renda_mensal'] as num?)?.toDouble() ?? 5000.0;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.buscarTransacoesStream(uid),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> transacoes = snapshot.data ?? [];

        // Filtra receitas do mês corrente
        double faturamentoMes = 0.0;
        int jobsCount = 0;
        double despesasMes = 0.0;

        final List<Map<String, dynamic>> jobsFreelancer = [];

        for (final t in transacoes) {
          final DateTime dt = FinancialUtils.extrairDataTransacao(t);
          final String tipo = t['tipo'] ?? 'Despesa';
          final double valor = (t['valor'] as num?)?.toDouble() ?? 0.0;
          final String cat = t['categoria'] ?? 'Outros';

          if (dt.year == agora.year && dt.month == agora.month) {
            if (tipo == 'Receita') {
              faturamentoMes += valor;
              jobsCount++;
            } else {
              despesasMes += valor;
            }
          }

          if (tipo == 'Receita' || cat == 'Freelancer') {
            jobsFreelancer.add(t);
          }
        }

        final double ticketMedio = jobsCount > 0
            ? faturamentoMes / jobsCount
            : 0.0;
        final double reservaRecomendada = despesasMes > 0
            ? despesasMes * 3
            : metaMensal * 1.5;
        final double progressoMeta = metaMensal > 0
            ? (faturamentoMes / metaMensal).clamp(0.0, 1.0)
            : 0.0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Banner Superior Modo Freelancer (Cor sólida azul, sem degradê)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
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
                      const Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.primaryYellow,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Modo Freelancer & Job',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(progressoMeta * 100).toStringAsFixed(0)}% da Meta',
                          style: const TextStyle(
                            color: AppColors.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Faturamento do Mês Atual',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${faturamentoMes.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Barra de progresso da meta
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressoMeta,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Linha de indicadores rápidos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meta Mensal',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'R\$ ${metaMensal.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Reserva Sugerida (3x)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'R\$ ${reservaRecomendada.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Grade de Métricas do Freelancer
            Row(
              children: [
                Expanded(
                  child: _buildFreelancerMetricCard(
                    titulo: 'Jobs no Mês',
                    valor: '$jobsCount ${jobsCount == 1 ? "job" : "jobs"}',
                    icone: Icons.work_outline,
                    cor: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFreelancerMetricCard(
                    titulo: 'Ticket Médio',
                    valor:
                        'R\$ ${ticketMedio.toStringAsFixed(2).replaceAll('.', ',')}',
                    icone: Icons.price_check_outlined,
                    cor: const Color(0xFF1976D2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Simulador Rápido de Valor / Hora de Trabalho
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cálculo de Hora Produtiva',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Considerando 30h semanais (120h no mês) para atingir sua meta de faturamento:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Valor Mínimo da Hora:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Text(
                            'R\$ ${(metaMensal / 120).toStringAsFixed(2).replaceAll('.', ',')} / hora',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Cabeçalho de Jobs & Projetos com Botão de Novo Job
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jobs & Receitas Recentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exibirDialogoNovoJobFreelancer,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text(
                    'Novo Job',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 5. Lista de Projetos ou Estado Vazio
            if (jobsFreelancer.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDF2F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.work_off_outlined,
                          color: AppColors.primaryBlue,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhum job registrado ainda',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Adicione seus projetos freelancer para acompanhar sua receita e projeções em tempo real.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...jobsFreelancer.map((job) {
                final String titulo = job['titulo'] ?? 'Job Freelancer';
                final double valor = (job['valor'] as num?)?.toDouble() ?? 0.0;
                final DateTime dt = FinancialUtils.extrairDataTransacao(job);
                final String dataFormatada =
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF2F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.business_center_outlined,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      dataFormatada,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: Text(
                      '+ R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  /// Constrói um card de métrica individual estilizado para o Modo Freelancer.
  Widget _buildFreelancerMetricCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF2F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: cor, size: 16),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Exibe o diálogo para cadastrar um novo job ou projeto freelancer no Firestore.
  void _exibirDialogoNovoJobFreelancer() {
    final tituloController = TextEditingController();
    final clienteController = TextEditingController();
    final valorController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.work_outline, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      'Novo Job Freelancer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título do Job / Projeto',
                    hintText: 'Ex: Desenvolvimento Website',
                    prefixIcon: const Icon(
                      Icons.title_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clienteController,
                  decoration: InputDecoration(
                    labelText: 'Cliente / Empresa (Opcional)',
                    hintText: 'Ex: Studio Alpha',
                    prefixIcon: const Icon(
                      Icons.business_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valorController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) =>
                      _formatarMoedaEmTempoReal(val, valorController),
                  decoration: InputDecoration(
                    labelText: 'Valor Negociado (R\$)',
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final double valor = _extrairValorMoeda(
                            valorController.text,
                          );
                          final String titulo = tituloController.text.trim();
                          final String cliente = clienteController.text.trim();

                          if (titulo.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Por favor, informe o título do projeto.',
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          if (valor <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Por favor, informe um valor maior que R\$ 0,00.',
                                ),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final String uid =
                              FirebaseFirestoreService.idClienteAtual;
                          final String tituloFinal = cliente.isNotEmpty
                              ? '$titulo ($cliente)'
                              : titulo;

                          Navigator.pop(modalCtx);

                          await _firestoreService.adicionarTransacao(
                            idCliente: uid,
                            titulo: tituloFinal,
                            valor: valor,
                            categoria: 'Freelancer',
                            tipo: 'Receita',
                            data: DateTime.now(),
                          );

                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Job "$titulo" adicionado com sucesso!',
                                ),
                                backgroundColor: AppColors.primaryBlue,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Salvar Job',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
