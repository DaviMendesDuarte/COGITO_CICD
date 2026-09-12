import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Gestão e Cadastro de Cartões de Crédito do aplicativo COGITO.
/// Segue a identidade visual e design da Dashboard: cabeçalho azul profundo,
/// cartões com cantos arredondados, visualização do Limite Disponível,
/// Fatura Atual e consumo visual do limite de crédito em tempo real.
class CartoesPage extends StatefulWidget {
  const CartoesPage({super.key});

  @override
  State<CartoesPage> createState() => _CartoesPageState();
}

class _CartoesPageState extends State<CartoesPage> {
  /// Instância do serviço Firebase Firestore para gerenciamento dos cartões.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Controller para rolagem suave da lista de cartões.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Converte a string de cor hexadecimal armazenada em uma instância de [Color].
  Color _parseColor(dynamic colorValue, Color fallback) {
    if (colorValue is Color) return colorValue;
    if (colorValue is String && colorValue.isNotEmpty) {
      try {
        final clean = colorValue.replaceAll('#', '').replaceAll('0x', '');
        return Color(int.parse('FF$clean', radix: 16));
      } catch (_) {}
    }
    return fallback;
  }

  /// Converte qualquer entrada numérica ou monetária em double com segurança.
  double _converterMoeda(String input) {
    if (input.trim().isEmpty) return 0.0;
    String limpo = input.replaceAll('R\$', '').replaceAll(' ', '').trim();
    if (limpo.contains(',') && limpo.contains('.')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    } else if (limpo.contains(',')) {
      limpo = limpo.replaceAll(',', '.');
    }
    return double.tryParse(limpo) ?? 0.0;
  }

  /// Abre o modal interativo inferior para cadastrar um novo cartão de crédito.
  void _exibirModalCadastrarCartao(String idCliente) {
    final formKey = GlobalKey<FormState>();
    final bancoController = TextEditingController(text: 'Nubank');
    final digitosController = TextEditingController();
    final limiteTotalController = TextEditingController();
    final faturaAtualController = TextEditingController(text: '0,00');
    final vencimentoController = TextEditingController(text: '10');

    String bandeiraSelecionada = 'Mastercard';
    String corSelecionada = '0xFF142251';
    String corFinalSelecionada = '0xFF244288';

    final List<String> bandeiras = ['Mastercard', 'Visa', 'Elo', 'American Express', 'Hipercard'];

    final List<Map<String, String>> paletas = [
      {'nome': 'Azul COGITO', 'inicial': '0xFF142251', 'final': '0xFF244288'},
      {'nome': 'Black Titanium', 'inicial': '0xFF1E1E1E', 'final': '0xFF3A3A3A'},
      {'nome': 'Laranja Gold', 'inicial': '0xFFF5891D', 'final': '0xFFFCAA17'},
      {'nome': 'Roxo Nubank', 'inicial': '0xFF8A05BE', 'final': '0xFFA020F0'},
      {'nome': 'Verde Esmeralda', 'inicial': '0xFF0E7A53', 'final': '0xFF149E6C'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalStateContext, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(modalStateContext).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Barra indicadora de arraste superior
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Cadastrar Novo Cartão',
                        style: TextStyles.poppinsBold(fontSize: 18, color: AppColors.primaryBlue),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicione seus dados para acompanhar o limite disponível e a fatura.',
                        style: TextStyles.poppinsRegular(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Campo: Instituição Financeira / Apelido
                      TextFormField(
                        controller: bancoController,
                        decoration: InputDecoration(
                          labelText: 'Nome do Banco ou Cartão',
                          hintText: 'Ex: Nubank, Itaú, COGITO Black',
                          prefixIcon: const Icon(Icons.account_balance, color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do cartão' : null,
                      ),
                      const SizedBox(height: 14),

                      // Campo: Bandeira do Cartão
                      DropdownButtonFormField<String>(
                        initialValue: bandeiraSelecionada,
                        items: bandeiras.map((b) {
                          return DropdownMenuItem(value: b, child: Text(b));
                        }).toList(),
                        onChanged: (novo) {
                          if (novo != null) setModalState(() => bandeiraSelecionada = novo);
                        },
                        decoration: InputDecoration(
                          labelText: 'Bandeira',
                          prefixIcon: const Icon(Icons.credit_card, color: AppColors.primaryBlue),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Linha: Últimos 4 dígitos e Dia de Vencimento
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: digitosController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'Últimos 4 dígitos',
                                hintText: '8829',
                                counterText: '',
                                prefixIcon: const Icon(Icons.password, color: AppColors.primaryBlue),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (v) => v == null || v.trim().length != 4 ? 'Digite 4 dígitos' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: vencimentoController,
                              keyboardType: TextInputType.number,
                              maxLength: 2,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: 'Dia do Vencimento',
                                hintText: '10',
                                counterText: '',
                                prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Informe o dia' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Linha: Limite Total e Fatura Atual
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: limiteTotalController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Limite Total (R\$)',
                                hintText: '5000.00',
                                prefixIcon: const Icon(Icons.payments_outlined, color: Colors.green),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Informe o limite';
                                final val = _converterMoeda(v);
                                if (val <= 0) return 'Valor inválido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: faturaAtualController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Fatura Atual (R\$)',
                                hintText: '1200.00',
                                prefixIcon: const Icon(Icons.receipt_long, color: AppColors.primaryOrange),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Informe a fatura';
                                final val = _converterMoeda(v);
                                if (val < 0) return 'Valor inválido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Escolha do estilo visual do cartão
                      Text(
                        'Estilo do Cartão',
                        style: TextStyles.poppinsBold(fontSize: 13, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: paletas.length,
                          itemBuilder: (context, idx) {
                            final p = paletas[idx];
                            final bool isSel = corSelecionada == p['inicial'];
                            final Color c1 = _parseColor(p['inicial'], AppColors.primaryBlue);

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  corSelecionada = p['inicial']!;
                                  corFinalSelecionada = p['final']!;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: c1,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSel ? Border.all(color: AppColors.primaryYellow, width: 2.5) : null,
                                ),
                                child: Center(
                                  child: Text(
                                    p['nome']!,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botão de salvar cartão
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final double limiteTotal = _converterMoeda(limiteTotalController.text);
                            final double faturaAtual = _converterMoeda(faturaAtualController.text);
                            final String nomeBanco = bancoController.text.trim();

                            Navigator.pop(modalContext);

                            await _firestoreService.salvarCartao(
                              idCliente: idCliente,
                              banco: nomeBanco,
                              bandeira: bandeiraSelecionada,
                              ultimosDigitos: digitosController.text.trim(),
                              limiteTotal: limiteTotal,
                              faturaAtual: faturaAtual,
                              vencimento: 'Dia ${vencimentoController.text.trim()}',
                              cor: corSelecionada,
                              corFinal: corFinalSelecionada,
                            );

                            if (mounted) {
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text('Cartão $nomeBanco cadastrado com sucesso!')),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            'SALVAR CARTÃO',
                            style: TextStyles.poppinsBold(fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.statusBarStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F8), // Fundo suave da Dashboard
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.buscarCartoesStream(idCliente),
          builder: (context, snapshot) {
            final List<Map<String, dynamic>> cartoes = snapshot.data ?? [];

            // Calcula os totais acumulados de todos os cartões cadastrados
            double totalLimite = 0.0;
            double totalFatura = 0.0;
            double totalDisponivel = 0.0;

            for (final c in cartoes) {
              final double lt = (c['limite_total'] as num?)?.toDouble() ?? 0.0;
              final double fa = (c['fatura_atual'] as num?)?.toDouble() ?? 0.0;
              final double ld = (c['limite_disponivel'] as num?)?.toDouble() ?? (lt - fa);

              totalLimite += lt;
              totalFatura += fa;
              totalDisponivel += ld;
            }

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 1. Cabeçalho superior no design de referência da Dashboard
                SliverToBoxAdapter(
                  child: _buildHeader(context, idCliente),
                ),

                // 2. Card de Resumo Geral com Limite Disponível e Fatura Atual
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildResumoGeralCard(totalLimite, totalFatura, totalDisponivel),
                    ),
                  ),
                ),

                // 3. Título da Seção e Botão Adicionar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cartões Ativos (${cartoes.length})',
                          style: TextStyles.poppinsBold(fontSize: 18, color: AppColors.primaryBlue),
                        ),
                        GestureDetector(
                          onTap: () => _exibirModalCadastrarCartao(idCliente),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 16, color: AppColors.primaryBlue),
                                const SizedBox(width: 4),
                                Text(
                                  'Novo Cartão',
                                  style: TextStyles.poppinsBold(fontSize: 13, color: AppColors.primaryBlue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Lista dos Cartões de Crédito cadastrados
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final c = cartoes[index];
                        return _buildCardItem(c, idCliente);
                      },
                      childCount: cartoes.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Constrói o cabeçalho superior azul idêntico ao da Dashboard.
  Widget _buildHeader(BuildContext context, String idCliente) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 52),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão de Cartões',
                    style: TextStyles.poppinsBold(fontSize: 20, color: Colors.white),
                  ),
                  Text(
                    'Limites disponíveis e faturas em tempo real',
                    style: TextStyles.poppinsRegular(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
            tooltip: 'Cadastrar Cartão',
            onPressed: () => _exibirModalCadastrarCartao(idCliente),
          ),
        ],
      ),
    );
  }

  /// Constrói o card superior de métricas agregadas com o limite total disponível e fatura.
  Widget _buildResumoGeralCard(double totalLimite, double totalFatura, double totalDisponivel) {
    final double percentUso = totalLimite > 0 ? (totalFatura / totalLimite).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
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
              Text(
                'VISÃO GERAL DOS LIMITES',
                style: TextStyles.poppinsBold(fontSize: 12, color: Colors.grey.shade600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(percentUso * 100).toStringAsFixed(0)}% em uso',
                  style: TextStyles.poppinsBold(fontSize: 11, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Limite Disponível
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Limite Disponível',
                      style: TextStyles.poppinsRegular(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'R\$ ${totalDisponivel.toStringAsFixed(2)}',
                      style: TextStyles.poppinsBold(fontSize: 20, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 38, color: Colors.grey.shade200),
              const SizedBox(width: 16),

              // Fatura Atual Acumulada
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fatura Atual Total',
                      style: TextStyles.poppinsRegular(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'R\$ ${totalFatura.toStringAsFixed(2)}',
                      style: TextStyles.poppinsBold(fontSize: 20, color: AppColors.primaryOrange),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progresso de comprometimento de limite
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentUso,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentUso > 0.85
                    ? Colors.red
                    : (percentUso > 0.6 ? AppColors.primaryOrange : AppColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Limite Concedido: R\$ ${totalLimite.toStringAsFixed(2)}',
              style: TextStyles.poppinsRegular(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  /// Renderiza o cartão visualmente e suas métricas financeiras detalhadas.
  Widget _buildCardItem(Map<String, dynamic> c, String idCliente) {
    final String banco = c['banco']?.toString() ?? 'Cartão COGITO';
    final String bandeira = c['bandeira']?.toString() ?? 'Mastercard';
    final String ultimos = c['ultimos_digitos']?.toString() ?? '0000';
    final String vencimento = c['vencimento']?.toString() ?? 'Dia 10';
    final String cartaoId = c['id']?.toString() ?? '';

    final double lt = (c['limite_total'] as num?)?.toDouble() ?? 0.0;
    final double fa = (c['fatura_atual'] as num?)?.toDouble() ?? 0.0;
    final double ld = (c['limite_disponivel'] as num?)?.toDouble() ?? (lt - fa);

    final double usoPercent = lt > 0 ? (fa / lt).clamp(0.0, 1.0) : 0.0;

    final Color cor1 = _parseColor(c['cor'], AppColors.primaryBlue);
    final Color cor2 = _parseColor(c['cor_final'], AppColors.secundaryBlue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Renderização do cartão físico com gradiente
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cor1, cor2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      banco,
                      style: TextStyles.poppinsBold(fontSize: 16, color: Colors.white),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bandeira,
                        style: TextStyles.poppinsBold(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  '•••• •••• •••• $ultimos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vencimento: $vencimento',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Icon(Icons.contactless, color: Colors.white70, size: 20),
                  ],
                ),
              ],
            ),
          ),

          // Informações de Limite Disponível e Fatura Atual
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Limite Disponível',
                          style: TextStyles.poppinsRegular(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'R\$ ${ld.toStringAsFixed(2)}',
                          style: TextStyles.poppinsBold(fontSize: 16, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Fatura Atual',
                          style: TextStyles.poppinsRegular(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'R\$ ${fa.toStringAsFixed(2)}',
                          style: TextStyles.poppinsBold(fontSize: 16, color: AppColors.primaryOrange),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Barra de consumo individual do cartão
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: usoPercent,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usoPercent > 0.85
                          ? Colors.red
                          : (usoPercent > 0.5 ? AppColors.primaryOrange : AppColors.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Limite Total: R\$ ${lt.toStringAsFixed(2)}',
                      style: TextStyles.poppinsRegular(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (cartaoId.isNotEmpty && !cartaoId.startsWith('card_default_'))
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Remover Cartão',
                        onPressed: () async {
                          final bool? confirma = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Remover Cartão'),
                              content: Text('Deseja realmente remover o cartão $banco?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Remover', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirma == true) {
                            await _firestoreService.removerCartao(cartaoId);
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
