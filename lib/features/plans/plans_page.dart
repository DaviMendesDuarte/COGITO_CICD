import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Planos e Assinaturas do COGITO.
/// Permite visualizar e selecionar os planos Grátis, Freelancer e Premium.
class PlanosPage extends StatefulWidget {
  const PlanosPage({super.key});

  @override
  State<PlanosPage> createState() => _PlanosPageState();
}

class _PlanosPageState extends State<PlanosPage> {
  /// Instância do serviço Firestore.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Nome do plano atual do usuário logado.
  String _planoAtual = 'Grátis';

  /// Estado de carregamento durante alteração de plano.
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final usuario = FirebaseFirestoreService.usuarioLogado;
    if (usuario != null && usuario['plano'] != null) {
      _planoAtual = usuario['plano'];
    }
  }

  /// Inicia o fluxo de contratação ou alteração de plano, exigindo confirmação de pagamento para planos pagos.
  void _iniciarTrocaPlano(String novoPlano, String preco) {
    if (novoPlano == _planoAtual) return;

    if (novoPlano == 'Grátis') {
      _exibirDialogoConfirmarDowngrade();
    } else {
      _exibirModalCheckoutGateway(novoPlano, preco);
    }
  }

  /// Exibe diálogo de confirmação para cancelamento de plano pago e reversão ao plano Grátis.
  void _exibirDialogoConfirmarDowngrade() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Alterar para Grátis'),
          ],
        ),
        content: const Text(
          'Ao retornar para o plano Grátis, os recursos avançados de IA e do Modo Freelancer serão limitados ao fim do ciclo atual. Deseja prosseguir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _efetivarPlanoNoFirestore('Grátis');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Exibe o Gateway de Checkout completo com opções de PIX Instantâneo, Cartão de Crédito e Carteira Digital.
  void _exibirModalCheckoutGateway(String novoPlano, String preco) {
    String metodoPagamento = 'PIX';
    final numeroCartaoController = TextEditingController();
    final titularController = TextEditingController();
    final validadeController = TextEditingController();
    final cvvController = TextEditingController();
    bool isProcessandoPagamento = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Alça do modal
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),

                    // Cabeçalho do Gateway
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.lock, color: AppColors.primaryBlue, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Checkout Seguro COGITO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                                Text('Ambiente Criptografado SSL 256-bit', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Card de Resumo do Pedido
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assinatura Plano $novoPlano', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                              const SizedBox(height: 2),
                              const Text('Renovação Mensal Automática', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Text(
                            preco,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text('Forma de Pagamento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),

                    // Seletor de Método de Pagamento (Pills)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetodoPagamentoPill(
                            label: 'PIX',
                            icon: Icons.pix,
                            isSelected: metodoPagamento == 'PIX',
                            onTap: () => setModalState(() => metodoPagamento = 'PIX'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetodoPagamentoPill(
                            label: 'Cartão',
                            icon: Icons.credit_card,
                            isSelected: metodoPagamento == 'Cartão',
                            onTap: () => setModalState(() => metodoPagamento = 'Cartão'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetodoPagamentoPill(
                            label: 'Carteiras',
                            icon: Icons.account_balance_wallet,
                            isSelected: metodoPagamento == 'Carteiras',
                            onTap: () => setModalState(() => metodoPagamento = 'Carteiras'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Conteúdo Dinâmico por Método Selecionado
                    if (metodoPagamento == 'PIX') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner, color: Colors.teal, size: 28),
                                SizedBox(width: 8),
                                Text('PIX com Aprovação Instantânea', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: const Column(
                                children: [
                                  Icon(Icons.qr_code_2, size: 100, color: AppColors.primaryBlue),
                                  SizedBox(height: 6),
                                  Text(
                                    '00020126580014br.gov.bcb.pix0136cogito-pagamentos@financeiro.app520400005303986',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: '00020126580014br.gov.bcb.pix0136cogito-pagamentos@financeiro.app5204000053039865802BR5925COGITO INTELIGENCIA FINAN6009SAO PAULO62070503***6304E2CA'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Código PIX Copia e Cola copiado com sucesso!'),
                                    backgroundColor: Colors.teal,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16, color: Colors.teal),
                              label: const Text('Copiar Código PIX', style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.teal)),
                            ),
                          ],
                        ),
                      ),
                    ] else if (metodoPagamento == 'Cartão') ...[
                      Column(
                        children: [
                          TextField(
                            controller: numeroCartaoController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Número do Cartão',
                              prefixIcon: const Icon(Icons.credit_card, color: AppColors.primaryBlue),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: titularController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Nome Impresso no Cartão',
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryBlue),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: validadeController,
                                  keyboardType: TextInputType.datetime,
                                  decoration: InputDecoration(
                                    labelText: 'Validade (MM/AA)',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: cvvController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet, color: AppColors.primaryBlue),
                                SizedBox(width: 8),
                                Text('Google Pay & Apple Pay', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Pague de forma rápida e segura utilizando os cartões cadastrados em sua carteira digital.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Botão Final de Confirmação & Pagamento
                    ElevatedButton(
                      onPressed: isProcessandoPagamento
                          ? null
                          : () async {
                              final navigator = Navigator.of(sheetCtx);
                              setModalState(() => isProcessandoPagamento = true);
                              // Simula comunicação segura com o gateway de pagamento (1.5s)
                              await Future.delayed(const Duration(milliseconds: 1400));
                              if (!mounted) return;
                              navigator.pop();
                              await _efetivarPlanoNoFirestore(novoPlano);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isProcessandoPagamento
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  metodoPagamento == 'PIX' ? 'Confirmar Pagamento PIX' : 'Concluir Pagamento ($preco)',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
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

  /// Botão seletor individual para cada método de pagamento do modal de checkout.
  Widget _buildMetodoPagamentoPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Altera efetivamente o plano de assinatura do usuário logado no Firestore e atualiza a interface.
  Future<void> _efetivarPlanoNoFirestore(String novoPlano) async {
    setState(() {
      _isLoading = true;
    });

    final usuario = FirebaseFirestoreService.usuarioLogado;
    final uid = usuario?['uid'] ?? usuario?['id_cliente'] ?? 'guest';

    await _firestoreService.atualizarPlano(uid.toString(), novoPlano);

    if (!mounted) return;

    setState(() {
      _planoAtual = novoPlano;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text('Plano "$novoPlano" ativado com sucesso! Aproveite seus benefícios.')),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Planos COGITO',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Banner Superior Informativo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.workspace_premium, color: AppColors.primaryYellow, size: 44),
                          SizedBox(height: 10),
                          Text(
                            'Escolha o Plano Perfeito para Você',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Desbloqueie todo o poder da inteligência financeira com o COGITO.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Card Plano Grátis
                    _buildPlanCard(
                      nome: 'Grátis',
                      preco: 'R\$ 0,00',
                      periodo: '/mês',
                      descricao: 'Ideal para quem está começando a organizar as finanças pessoais.',
                      recursos: [
                        'Controle de receitas e despesas manuais',
                        'Relatórios visuais simplificados',
                        'Vinculação de 1 conta bancária',
                        'Acesso às dicas diárias do CONRADO',
                      ],
                      corHeader: Colors.grey.shade700,
                      isAtual: _planoAtual == 'Grátis',
                    ),

                    const SizedBox(height: 20),

                    // Card Plano Freelancer
                    _buildPlanCard(
                      nome: 'Freelancer',
                      preco: 'R\$ 5,90',
                      periodo: '/mês',
                      descricao: 'Perfeito para profissionais autônomos com receitas variáveis.',
                      recursos: [
                        'Todos os recursos do plano Grátis',
                        'Modo Freelancer de gestão de fluxo de caixa',
                        'Sistema de envelopes de destinos personalizados',
                        'Simulador de reserva para meses de baixa receita',
                        'Exportação de extratos em PDF/Excel',
                      ],
                      corHeader: AppColors.primaryOrange,
                      badge: 'RECOMENDADO PARA AUTÔNOMOS',
                      isAtual: _planoAtual == 'Freelancer',
                    ),

                    const SizedBox(height: 20),

                    // Card Plano Premium
                    _buildPlanCard(
                      nome: 'Premium',
                      preco: 'R\$ 15,90',
                      periodo: '/mês',
                      descricao: 'Experiência completa com Inteligência Artificial e múltiplos chats.',
                      recursos: [
                        'Todos os recursos do plano Freelancer',
                        'Assistente IA CONRADO ilimitado 24/7',
                        'Múltiplos chats simultâneos no CONRADO',
                        'Categorização automática inteligente por IA',
                        'Suporte prioritário e consultoria financeira personalizada',
                      ],
                      corHeader: AppColors.primaryBlue,
                      badge: 'MAIS POPULAR & COMPLETO',
                      isDestaque: true,
                      isAtual: _planoAtual == 'Premium',
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  /// Constrói um card de plano de assinatura com badge de destaque e lista de benefícios.
  Widget _buildPlanCard({
    required String nome,
    required String preco,
    required String periodo,
    required String descricao,
    required List<String> recursos,
    required Color corHeader,
    String? badge,
    bool isDestaque = false,
    bool isAtual = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAtual
              ? Colors.green
              : (isDestaque ? AppColors.primaryBlue : Colors.grey.shade300),
          width: isAtual || isDestaque ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDestaque
                ? AppColors.primaryBlue.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badge Superior se houver
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: corHeader,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      nome,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: corHeader,
                      ),
                    ),
                    if (isAtual)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'PLANO ATUAL',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      preco,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secundaryBlue,
                      ),
                    ),
                    Text(
                      periodo,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const Divider(height: 28),

                // Lista de Benefícios
                ...recursos.map(
                  (recurso) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recurso,
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botão de Seleção
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isAtual ? null : () => _iniciarTrocaPlano(nome, preco),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAtual ? Colors.grey.shade300 : corHeader,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: isAtual ? 0 : 2,
                    ),
                    child: Text(
                      isAtual ? 'PLANO ATIVO' : 'SELECIONAR PLANO',
                      style: TextStyle(
                        color: isAtual ? Colors.grey.shade700 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
