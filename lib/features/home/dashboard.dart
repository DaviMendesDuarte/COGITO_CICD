import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/features/finances/cartoes_page.dart';
import 'package:cogito/features/finances/detailed_analysis_page.dart';
import 'package:cogito/features/finances/financial_goals_page.dart';
import 'package:cogito/features/notifications/notifications_page.dart';
import 'package:cogito/features/user/link_bank_account_page.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Tela do Dashboard principal do aplicativo COGITO.
/// Apresenta a interface do aplicativo perfeitamente alinhada ao design de referência visual,
/// utilizando tipografia Poppins (Bold e Regular) e as cores da marca COGITO.
class Dashboard extends StatefulWidget {
  /// Callback para alternância de abas no container de navegação pai ([HomePage]).
  /// Aceita o índice da aba principal e opcionalmente o índice da sub-aba (ex: sub-aba 1 de Orçamentos na FinancasPage).
  final void Function(int tabIndex, [int? subTabIndex])? onNavigateToTab;

  const Dashboard({super.key, this.onNavigateToTab});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  /// Controller de rolagem para monitorar o scroll da tela e atualizar a status bar se necessário.
  final ScrollController _scrollController = ScrollController();

  /// Flag que controla a visibilidade dos valores financeiros na tela.
  bool _isSaldoVisivel = true;

  /// Plano do usuário carregado a partir do Firestore.
  String _planoUsuario = 'Grátis';

  /// Serviço do Firebase Firestore para sincronização de dados.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  @override
  void initState() {
    super.initState();
    _carregarPlanoUsuario();
  }

  /// Carrega o plano do usuário ativo no Cloud Firestore.
  Future<void> _carregarPlanoUsuario() async {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;
    final perfil = await _firestoreService.buscarUsuario(idCliente);

    if (mounted && perfil != null && perfil['plano'] != null) {
      setState(() {
        _planoUsuario = perfil['plano'];
      });
    }
  }

  /// Atualiza reativamente os dados da Dashboard ao efetuar o gesto Pull-to-Refresh.
  Future<void> _atualizarDadosDashboard() async {
    await _carregarPlanoUsuario();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Exibe o modal detalhado do cartão selecionado pelo usuário.
  void _exibirDetalhesCartao(Map<String, dynamic> cartao, String nomeTitular) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cartao['banco'].toString(),
                      style: TextStyles.poppinsBold(
                        fontSize: 20,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cartao['bandeira'].toString(),
                        style: TextStyles.poppinsBold(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoItem(
                  Icons.credit_card,
                  'Número do Cartão',
                  cartao['numero'].toString(),
                ),
                const SizedBox(height: 12),
                _buildInfoItem(Icons.person_outline, 'Titular', nomeTitular),
                const SizedBox(height: 12),
                _buildInfoItem(
                  Icons.account_balance_wallet_outlined,
                  'Limite Disponível',
                  cartao['limite_disponivel'] != null
                      ? 'R\$ ${(cartao['limite_disponivel'] as num).toStringAsFixed(2)}'
                      : (cartao['limite']?.toString() ?? 'R\$ 0,00'),
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  Icons.receipt_long_outlined,
                  'Fatura Atual',
                  cartao['fatura_atual'] != null
                      ? 'R\$ ${(cartao['fatura_atual'] as num).toStringAsFixed(2)}'
                      : 'R\$ 0,00',
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  Icons.calendar_today_outlined,
                  'Vencimento',
                  cartao['vencimento']?.toString() ?? cartao['validade']?.toString() ?? 'Dia 10',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Fechar',
                      style: TextStyles.poppinsBold(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Constrói um item de informação no modal de detalhes do cartão.
  Widget _buildInfoItem(IconData icone, String rotulo, String valor) {
    return Row(
      children: [
        Icon(icone, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: TextStyles.poppinsRegular(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              valor,
              style: TextStyles.poppinsBold(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseFirestoreService.usuarioLogado;
    final String nomeUsuario = usuario?['nome'] ?? 'Usuário';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.statusBarStyle,
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF3F4F8,
        ), // Fundo leve cinza-azulado idêntico à imagem
        body: RefreshIndicator(
          onRefresh: _atualizarDadosDashboard,
          color: AppColors.primaryBlue,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 1. Cabeçalho superior azul escuro com Avatar e Notificações (Notch & Status bar area)
                _buildHeader(context),

                // 2. Container dos cards sobrepostos com translação negativa para sobreposição suave
                Transform.translate(
                  offset: const Offset(0, -35),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // CARD 1: SALDO TOTAL (com barra vertical azul estendida até embaixo do valor de 32px e separação cinza aparente)
                        _buildBalanceCard(),

                        const SizedBox(height: 16),

                        // CARD 2: "Entenda o CONRADO" (com Insights inteligentes do Conrado e botão para conversar)
                        _buildConradoCard(),

                        const SizedBox(height: 16),

                        // CARD 3: "Acesso Rápido" (card branco com ícone de bandeira e opções rápidas)
                        _buildAcessoRapidoCard(context),

                        const SizedBox(height: 20),

                        // SEÇÃO 4: "Meus Cartões" (título 18 + "Deslize >" 18, botão "+" quadrado 56x56 e carrossel de cartões deslizáveis)
                        _buildMeusCartoesSection(nomeUsuario),

                        const SizedBox(height: 20),

                        // SEÇÃO EXTRA: Carrossel de Metas & Caixinhas
                        _buildMetasFinanceirasSection(context),

                        const SizedBox(height: 20),

                        // SEÇÃO EXTRA: Transações Recentes
                        _buildTransacoesRecentesSection(context),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho superior em tom Azul Escuro com foto de perfil e ícone de sino com notificação.
  /// Obtém as informações do usuário autenticado para ouvir a stream de notificações do Firestore.
  Widget _buildHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    // Obtém os dados do usuário atualmente autenticado no Firebase
    final usuario = FirebaseFirestoreService.usuarioLogado;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 55),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue, // Cor azul escura principal
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ícone de Perfil de Usuário com indicação do plano ativo no Tooltip
          GestureDetector(
            onTap: () =>
                widget.onNavigateToTab?.call(3), // Navega para a aba de Perfil
            child: Tooltip(
              message: 'Plano $_planoUsuario',
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primaryBlue,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // Botão de notificação reativo com ícone de sino e ponto indicador de não lidas via Firebase Stream
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.buscarNotificacoesStream(
              (usuario?['uid'] ?? usuario?['id_cliente'] ?? 'guest').toString(),
            ),
            builder: (context, snapshot) {
              final notifs = snapshot.data ?? [];
              final bool temNaoLidas = notifs.any((n) => n['lida'] != true);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificacoesPage(),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                    if (temNaoLidas)
                      Positioned(
                        top: 0,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Constrói o Card de Saldo Total flutuante em tempo real no Cloud Firestore.
  /// A linha azul vertical estende-se até embaixo do valor da fonte 32px, a separação cinza é aparente
  /// e o valor utiliza a fonte Poppins Bold de tamanho 32.
  Widget _buildBalanceCard() {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.buscarContasBancariasStream(idCliente),
      builder: (context, snapshotContas) {
        final List<Map<String, dynamic>> contas = snapshotContas.data ?? [];
        final int totalContasCount = contas.isEmpty ? 2 : contas.length;
        final String textoContas =
            'Saldo consolidado - $totalContasCount ${totalContasCount == 1 ? 'conta' : 'contas'}';

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.buscarTransacoesStream(idCliente),
          builder: (context, snapshotTransacoes) {
            final List<Map<String, dynamic>> transacoes =
                snapshotTransacoes.data ?? [];

            double saldoBaseContas = 0.0;
            for (final c in contas) {
              saldoBaseContas += (c['saldo'] as num?)?.toDouble() ?? 0.0;
            }

            double totalEntradas = 0.0;
            double totalSaidas = 0.0;

            for (final t in transacoes) {
              final double valor = (t['valor'] as num?)?.toDouble() ?? 0.0;
              final String tipo = t['tipo'] ?? 'Receita';
              if (tipo == 'Receita') {
                totalEntradas += valor;
              } else {
                totalSaidas += valor;
              }
            }

            final double saldoCalculado = saldoBaseContas + totalEntradas - totalSaidas;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção superior do card com o saldo e a barra azul vertical
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Utiliza IntrinsicHeight para garantir que a barra azul vá do topo do título até a base do valor
                        Expanded(
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Barra vertical azul acompanhando as 3 linhas de texto (título, subtítulo e valor)
                                Container(
                                  width: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Título "SALDO TOTAL" em Poppins Bold tamanho 16
                                      Text(
                                        'SALDO TOTAL',
                                        style: TextStyles.poppinsBold(
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // Subtítulo "Saldo consolidado - X contas" em Poppins Regular tamanho 14
                                      Text(
                                        textoContas,
                                        style: TextStyles.poppinsRegular(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Valor do Saldo Total com fonte Poppins Bold tamanho 32
                                      Text(
                                        _isSaldoVisivel
                                            ? 'R\$ ${saldoCalculado.toStringAsFixed(2).replaceAll('.', ',')}'
                                            : '••••••••',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyles.poppinsBold(
                                          fontSize: 32,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Ícone de olho no canto superior direito para alternar a visibilidade do saldo
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _isSaldoVisivel
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textPrimary,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSaldoVisivel = !_isSaldoVisivel;
                            });
                          },
                          tooltip: 'Mostrar/Ocultar Saldo',
                        ),
                      ],
                    ),
                  ),

                  // Linha de divisão horizontal que vai de borda a borda do card
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

                  // Seção inferior com o botão de análise de gastos e relatórios
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AnaliseDetalhadaPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.signal_cellular_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          'Análise de gastos & Relatórios',
                          style: TextStyles.poppinsBold(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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

  /// Constrói o Card "Entenda o CONRADO" com o título (tamanho 18),
  /// os insights inteligentes que o Conrado diz (tamanho 14) e o botão para conversar.
  Widget _buildConradoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue, // Fundo azul escuro principal
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha de título com ícone de coroa em destaque posicionado mais para cima e "Entenda o CONRADO" em Poppins Bold tamanho 18
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone autêntico de coroa em branco
              Icon(
                MdiIcons.crown,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Entenda o CONRADO',
                style: TextStyles.poppinsBold(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Área de Insights do CONRADO (O que a inteligência do Conrado fala para o usuário)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.amberAccent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Você economizou 12% a mais este mês! Mantendo esse ritmo, sua reserva de emergência estará completa em 4 meses.',
                    style: TextStyles.poppinsRegular(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botão pill branco com texto azul escuro "Conversar com o CONRADO" em Poppins Bold tamanho 14
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(2); // Direciona para a aba do Conrado
                }
              },
              icon: const Icon(
                Icons.signal_cellular_alt_rounded,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              label: Text(
                'Conversar com o CONRADO',
                style: TextStyles.poppinsBold(
                  fontSize: 14,
                  color: AppColors.primaryBlue,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o Card "Acesso Rápido" com título (tamanho 18) com ícone de trovão e itens de subtítulo (tamanho 14).
  Widget _buildAcessoRapidoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção "Acesso Rápido" com ícone de trovão (flash_on_rounded) em Poppins Bold tamanho 18
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded, // Ícone de trovão/raio
                color: AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Acesso Rápido',
                style: TextStyles.poppinsBold(
                  fontSize: 18,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Itens de atalho rápido (Análise, Orçamentos e Vincular Contas Bancárias)
          Row(
            children: [
              Expanded(
                child: _buildAcessoRapidoItem(
                  context,
                  titulo: 'Análise',
                  icon: Icons.analytics_outlined,
                  color: AppColors.primaryBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnaliseDetalhadaPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAcessoRapidoItem(
                  context,
                  titulo: 'Orçamentos',
                  icon: Icons.pie_chart_outline,
                  color: AppColors.primaryOrange,
                  onTap: () => widget.onNavigateToTab?.call(1, 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAcessoRapidoItem(
                  context,
                  titulo: 'Bancos',
                  icon: Icons.account_balance_outlined,
                  color: Colors.purple.shade600,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VincularContaBancariaPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói um item individual de atalho para o container de Acesso Rápido.
  Widget _buildAcessoRapidoItem(
    BuildContext context, {
    required String titulo,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              titulo,
              style: TextStyles.poppinsBold(fontSize: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// Retorna uma instância de [Color] a partir de uma cor dinâmica ou hexadecimal.
  Color _obterCorCartao(dynamic valor, Color fallback) {
    if (valor is Color) return valor;
    if (valor is String && valor.isNotEmpty) {
      try {
        final clean = valor.replaceAll('#', '').replaceAll('0x', '');
        return Color(int.parse('FF$clean', radix: 16));
      } catch (_) {}
    }
    return fallback;
  }

  /// Constrói a Seção "Meus Cartões" com título "Meus Cartões" (tamanho 18), "Deslize >" (tamanho 18),
  /// o botão azul escuro "+" quadrado (56x56) que direciona para a nova tela [CartoesPage]
  /// e carrossel deslizável sincronizado em tempo real com o Cloud Firestore.
  Widget _buildMeusCartoesSection(String nomeTitular) {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.buscarCartoesStream(idCliente),
      builder: (context, snapshot) {
        final cartoes = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha de cabeçalho da seção com o texto "Meus Cartões" e "Deslize >" com atalho para a CartoesPage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meus Cartões',
                  style: TextStyles.poppinsBold(
                    fontSize: 18,
                    color: AppColors.primaryBlue,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartoesPage(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'Deslize',
                        style: TextStyles.poppinsBold(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Linha contendo o botão escuro "+" quadrado (56x56) e o carrossel de cartões deslizáveis estilizados
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botão quadrado azul escuro com altura exatamente igual à largura (56x56)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartoesPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Carrossel deslizável horizontal com os cartões de crédito/débito do usuário
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cartoes.length,
                      itemBuilder: (context, index) {
                        final c = cartoes[index];
                        final Color corInicial = _obterCorCartao(c['cor'] ?? c['corInicial'], AppColors.primaryBlue);

                        final double? ld = (c['limite_disponivel'] as num?)?.toDouble();
                        final String strLimiteDisp = ld != null
                            ? 'R\$ ${ld.toStringAsFixed(2)}'
                            : (c['limite']?.toString() ?? 'R\$ 0,00');

                        return GestureDetector(
                          onTap: () => _exibirDetalhesCartao(c, nomeTitular),
                          child: Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: corInicial,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: corInicial.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      c['banco'].toString(),
                                      style: TextStyles.poppinsBold(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c['bandeira'].toString(),
                                        style: TextStyles.poppinsBold(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  c['numero'].toString(),
                                  style: TextStyles.poppinsBold(
                                    fontSize: 14,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TITULAR',
                                          style: TextStyles.poppinsRegular(
                                            fontSize: 9,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          nomeTitular,
                                          style: TextStyles.poppinsBold(
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'DISPONÍVEL',
                                          style: TextStyles.poppinsRegular(
                                            fontSize: 9,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          strLimiteDisp,
                                          style: TextStyles.poppinsBold(
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Constrói a Seção "Metas Financeiras" com metas reais cadastradas no Firebase Firestore,
  /// ícones simples e barra de progresso na cor azul, e atalho "Ver todas" em cinza.
  Widget _buildMetasFinanceirasSection(BuildContext context) {
    // Identificador único do cliente para consulta no Firestore
    final String idCliente = FirebaseFirestoreService.idClienteAtual;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.buscarMetasStream(idCliente),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> metasFirestore = snapshot.data ?? [];
        final List<Map<String, dynamic>> metasEmAndamento = metasFirestore
            .where((m) => (m['status'] ?? 'em_andamento') == 'em_andamento')
            .toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.primaryBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Metas Financeiras',
                        style: TextStyles.poppinsBold(
                          fontSize: 18,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MetasFinanceirasPage(),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Ver todas',
                          style: TextStyles.poppinsBold(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Caso ainda não haja metas cadastradas, exibe card informativo para criação
              if (metasEmAndamento.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        color: AppColors.primaryBlue,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma meta cadastrada ainda',
                        style: TextStyles.poppinsBold(
                          fontSize: 14,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Crie suas caixinhas de economia e acompanhe seu progresso.',
                        textAlign: TextAlign.center,
                        style: TextStyles.poppinsRegular(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MetasFinanceirasPage(),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text(
                          'Criar Meta',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                )
              else
                // Carrossel deslizável de cartões de Metas Financeiras reais
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: metasEmAndamento.map((meta) {
                      final String titulo = meta['titulo'] ?? 'Meta';
                      final String? categoria = meta['categoria']?.toString();
                      final double atual = (meta['valor_atual'] as num?)?.toDouble() ?? 0.0;
                      final double objetivo = (meta['valor_objetivo'] as num?)?.toDouble() ?? 1.0;
                      final double progresso = (atual / objetivo).clamp(0.0, 1.0);
                      final int porcentagem = (progresso * 100).toInt();

                      return Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Linha superior com ícone simples em azul e porcentagem em azul
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Ícone simples na cor azul COGITO
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _obterIconeSimplesMeta(categoria),
                                    color: AppColors.primaryBlue,
                                    size: 22,
                                  ),
                                ),
                                // Porcentagem de progresso em destaque azul
                                Text(
                                  '$porcentagem%',
                                  style: TextStyles.poppinsBold(
                                    fontSize: 15,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Título da Meta
                            Text(
                              titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.poppinsBold(
                                fontSize: 15,
                                color: AppColors.secundaryBlue,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Barra de Progresso Arredondada na cor azul
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progresso,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Valores de saldo acumulado e objetivo final
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'R\$ ${atual.toStringAsFixed(0)}',
                                  style: TextStyles.poppinsRegular(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'R\$ ${objetivo.toStringAsFixed(0)}',
                                  style: TextStyles.poppinsBold(
                                    fontSize: 14,
                                    color: AppColors.secundaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Retorna um ícone simples e direto de acordo com a categoria da meta cadastrada.
  IconData _obterIconeSimplesMeta(String? categoria) {
    switch (categoria?.toLowerCase()) {
      case 'reserva':
        return Icons.savings_outlined;
      case 'viagem':
        return Icons.flight_takeoff_outlined;
      case 'veículo':
      case 'veiculo':
      case 'carro':
        return Icons.directions_car_outlined;
      case 'imóvel':
      case 'imovel':
      case 'casa':
        return Icons.home_outlined;
      case 'educação':
      case 'educacao':
        return Icons.school_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  /// Constrói a lista das últimas transações financeiras no formato vertical.
  Widget _buildTransacoesRecentesSection(BuildContext context) {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.buscarTransacoesStream(idCliente),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> transacoes = snapshot.data ?? [];
        final ultimasTransacoes = transacoes.take(4).toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        color: AppColors.primaryBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Transações Recentes',
                        style: TextStyles.poppinsBold(
                          fontSize: 18,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateToTab?.call(1),
                    child: Text(
                      'Extrato ➔',
                      style: TextStyles.poppinsBold(
                        fontSize: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              // Espaçamento vertical entre o cabeçalho de transações e a lista/mensagem
              const SizedBox(height: 2),

              if (ultimasTransacoes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Nenhuma transação registrada.',
                      style: TextStyles.poppinsRegular(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ultimasTransacoes.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 33, thickness: 2),
                  itemBuilder: (context, index) {
                    final t = ultimasTransacoes[index];
                    final String tipo = t['tipo'] ?? 'Receita';
                    final bool isReceita = tipo == 'Receita';
                    final double valor =
                        (t['valor'] as num?)?.toDouble() ?? 0.0;

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isReceita
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isReceita
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isReceita ? Colors.green : Colors.red,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['titulo'] ?? 'Lançamento',
                                style: TextStyles.poppinsBold(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                t['categoria'] ?? 'Geral',
                                style: TextStyles.poppinsRegular(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isReceita ? '+' : '-'} R\$ ${valor.toStringAsFixed(2)}',
                          style: TextStyles.poppinsBold(
                            fontSize: 14,
                            color: isReceita ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
