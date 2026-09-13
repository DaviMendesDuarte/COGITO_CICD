import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/features/home/home_page.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Informações Adicionais (Onboarding Pós-Cadastro).
/// Exibida imediatamente após o cadastro (com e-mail/senha ou Google).
/// Baseada no design da Dashboard com cabeçalho azul, cartões modernos,
/// campos obrigatórios de idade, tipo de renda (fixa ou freelancer com ativação de funções)
/// e aceite obrigatório dos Termos de Uso e Políticas de Privacidade.
class PrimeirosPassosPage extends StatefulWidget {
  const PrimeirosPassosPage({super.key});

  @override
  State<PrimeirosPassosPage> createState() => _PrimeirosPassosPageState();
}

class _PrimeirosPassosPageState extends State<PrimeirosPassosPage> {
  /// Instância do serviço Firebase Firestore.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Chave global do formulário para validação dos campos obrigatórios.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Controladores dos campos de texto.
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _rendaMensalController = TextEditingController();

  /// Tipo de renda selecionado ('Salario_Fixo' ou 'Freelancer').
  String _tipoRenda = 'Salario_Fixo';

  /// Controle de aceite dos Termos de Uso e Políticas de Privacidade.
  bool _concordaTermos = false;

  /// Estado de carregamento e salvamento.
  bool _isSaving = false;

  /// Controller de rolagem da tela.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Pré-carrega valores caso o usuário já possua dados básicos do Google Auth ou Firestore
    final usuario = FirebaseFirestoreService.usuarioLogado;
    final authUser = FirebaseAuth.instance.currentUser;

    if (usuario != null) {
      if (usuario['idade'] != null && usuario['idade'] != 0) {
        _idadeController.text = usuario['idade'].toString();
      }
      if (usuario['telefone'] != null &&
          usuario['telefone'].toString().isNotEmpty) {
        _telefoneController.text = usuario['telefone'].toString();
      }
      if (usuario['renda_mensal'] != null &&
          (usuario['renda_mensal'] as num) > 0) {
        _rendaMensalController.text = usuario['renda_mensal'].toString();
      }
      if (usuario['tipo_renda'] != null) {
        _tipoRenda = usuario['tipo_renda'].toString().contains('Free')
            ? 'Freelancer'
            : 'Salario_Fixo';
      }
    } else if (authUser?.phoneNumber != null &&
        authUser!.phoneNumber!.isNotEmpty) {
      _telefoneController.text = authUser.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _idadeController.dispose();
    _telefoneController.dispose();
    _rendaMensalController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Constrói um cartão visual estilizado com ícone, título e descrição para os termos e políticas.
  Widget _buildTermItemCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.poppinsBold(
                    fontSize: 13,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyles.poppinsRegular(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Exibe modal bottom sheet detalhado e moderno com os Termos de Uso do COGITO.
  void _exibirDialogoTermosDeUso() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (modalCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                children: [
                  // Alça de arraste superior
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
                  const SizedBox(height: 18),

                  // Cabeçalho com ícone e badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Termos de Uso',
                              style: TextStyles.poppinsBold(
                                fontSize: 19,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Text(
                              'Versão 2026 • Documento Oficial COGITO',
                              style: TextStyles.poppinsRegular(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Lista de tópicos informativos
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildTermItemCard(
                          icon: Icons.verified_user_outlined,
                          iconColor: AppColors.primaryBlue,
                          title: '1. Compromisso e Veracidade',
                          description:
                              'Ao utilizar o COGITO, você se compromete a inserir dados financeiros autênticos para garantir a confiabilidade das projeções e relatórios gerados.',
                        ),
                        _buildTermItemCard(
                          icon: Icons.auto_awesome,
                          iconColor: AppColors.primaryOrange,
                          title: '2. Inteligência Artificial CONRADO',
                          description:
                              'Nossa inteligência artificial oferece análises estatísticas e sugestões orçamentárias com foco educacional e orientativo, sendo as decisões tomadas sob livre arbítrio do usuário.',
                        ),
                        _buildTermItemCard(
                          icon: Icons.business_center_outlined,
                          iconColor: const Color(0xFF0E7A53),
                          title: '3. Modo Freelancer & Ferramentas',
                          description:
                              'O perfil Freelancer desbloqueia recursos especializados para gestão de fluxo de caixa volátil, cobranças e clientes, podendo ser ativado ou desativado livremente nas configurações do perfil.',
                        ),
                        _buildTermItemCard(
                          icon: Icons.lock_outline,
                          iconColor: Colors.deepPurple,
                          title: '4. Soberania e Propriedade dos Dados',
                          description:
                              'Todas as anotações, contas cadastradas e faturas pertencem exclusivamente a você. É possível solicitar a exportação ou exclusão definitiva dos dados a qualquer momento.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Botão de ação inferior
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        setState(() => _concordaTermos = true);
                      },
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'LI E CONCORDO COM OS TERMOS',
                        style: TextStyles.poppinsBold(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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

  /// Exibe modal bottom sheet detalhado e moderno com a Política de Privacidade do COGITO.
  void _exibirDialogoPoliticaPrivacidade() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (modalCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                children: [
                  // Alça de arraste superior
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
                  const SizedBox(height: 18),

                  // Cabeçalho com ícone e badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E7A53).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF0E7A53),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Política de Privacidade',
                              style: TextStyles.poppinsBold(
                                fontSize: 19,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Text(
                              'Conformidade LGPD • Proteção de Dados',
                              style: TextStyles.poppinsRegular(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Lista de tópicos informativos
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildTermItemCard(
                          icon: Icons.lock_outline,
                          iconColor: AppColors.primaryBlue,
                          title: '1. Criptografia Ponta a Ponta',
                          description:
                              'Seus dados pessoais, rendas e registros são transmitidos por conexões criptografadas com protocolos SSL/TLS de nível bancário e armazenados em nuvem segura.',
                        ),
                        _buildTermItemCard(
                          icon: Icons.visibility_off_outlined,
                          iconColor: const Color(0xFF0E7A53),
                          title: '2. Não Compartilhamento com Terceiros',
                          description:
                              'O COGITO nunca comercializa, monetiza ou fornece suas informações para empresas de publicidade ou terceiros não autorizados.',
                        ),
                        _buildTermItemCard(
                          icon: Icons.credit_card_outlined,
                          iconColor: AppColors.primaryOrange,
                          title: '3. Mascaramento e Tokenização',
                          description:
                              'Informações de cartões e contas financeiras são mascaradas, exibindo apenas os últimos 4 dígitos para identificação sem expor dados confidenciais.',
                        ),
                        _buildTermItemCard(
                          icon: Icons.policy_outlined,
                          iconColor: Colors.deepPurple,
                          title: '4. Adequação Integral à LGPD',
                          description:
                              'Atuamos em rigorosa conformidade com a Lei Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018), assegurando total transparência sobre o tratamento das suas informações.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Botão de ação inferior
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        setState(() => _concordaTermos = true);
                      },
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'CONCORDAR E CONTINUAR',
                        style: TextStyles.poppinsBold(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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

  /// Salva as informações adicionais no Cloud Firestore e redireciona para a HomePage.
  Future<void> _concluirCadastro() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Preencha os campos obrigatórios para continuar.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (!_concordaTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Você precisa concordar com os Termos de Uso e Políticas de Privacidade para prosseguir.',
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final authUser = FirebaseAuth.instance.currentUser;
    final usuario = FirebaseFirestoreService.usuarioLogado;

    final String uid = FirebaseFirestoreService.idClienteAtual;
    final String nome =
        usuario?['nome'] ?? authUser?.displayName ?? 'Usuário COGITO';
    final String email =
        usuario?['email'] ?? authUser?.email ?? 'usuario@cogito.com';
    final int idade = int.tryParse(_idadeController.text.trim()) ?? 18;
    final double renda =
        double.tryParse(
          _rendaMensalController.text
              .replaceAll(',', '.')
              .replaceAll('R\$', '')
              .trim(),
        ) ??
        0.0;

    final bool isFreelancer = _tipoRenda == 'Freelancer';
    final String planoDefinido = isFreelancer ? 'Freelancer' : 'Grátis';

    // Salva perfil completo com tipo de renda e plano no Firestore
    await _firestoreService.salvarPerfilUsuario(
      uid: uid,
      nome: nome,
      email: email,
      telefone: _telefoneController.text.trim(),
      idade: idade,
      tipoRenda: _tipoRenda,
      rendaMensal: renda,
    );

    // Garante atualização de privilégios de plano no Firestore
    await _firestoreService.atualizarPlano(uid, planoDefinido);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFreelancer
              ? 'Perfil concluído! Modo Freelancer ativado com sucesso.'
              : 'Cadastro concluído com sucesso! Bem-vindo(a) ao COGITO.',
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.statusBarStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F8), // Fundo idêntico à Dashboard
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Cabeçalho institucional azul no padrão Dashboard
              _buildHeader(context),

              // Card flutuante sobreposto com cantos arredondados
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Campo Idade (Obrigatório)
                          Text(
                            'Sua Idade *',
                            style: TextStyles.poppinsBold(
                              fontSize: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _idadeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'Ex: 25',
                              prefixIcon: const Icon(
                                Icons.cake_outlined,
                                color: AppColors.primaryBlue,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Informe sua idade';
                              final n = int.tryParse(v.trim());
                              if (n == null || n < 12 || n > 120)
                                return 'Informe uma idade válida';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // 2. Seletor de Tipo de Renda (Fixa x Freelancer)
                          Text(
                            'Tipo de Renda *',
                            style: TextStyles.poppinsBold(
                              fontSize: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Caso escolha Freelancer, todas as ferramentas para autônomos serão liberadas automaticamente (você poderá trocar a qualquer momento no seu perfil).',
                            style: TextStyles.poppinsRegular(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildOpcaoTipoRenda(
                                  titulo: 'Renda Fixa',
                                  subtitulo: 'CLT / Funcionário',
                                  icone: Icons.badge_outlined,
                                  tipoValor: 'Salario_Fixo',
                                  corTema: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildOpcaoTipoRenda(
                                  titulo: 'Freelancer',
                                  subtitulo: 'Autônomo / PJ',
                                  icone: Icons.work_outline,
                                  tipoValor: 'Freelancer',
                                  corTema: AppColors.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 3. Campo Renda Mensal Estimada
                          Text(
                            'Renda Mensal Estimada (R\$)',
                            style: TextStyles.poppinsBold(
                              fontSize: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _rendaMensalController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ex: 3500.00',
                              prefixIcon: const Icon(
                                Icons.attach_money,
                                color: Colors.green,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4. Campo Telefone de Contato (Opcional/Complementar)
                          Text(
                            'Telefone para Contato',
                            style: TextStyles.poppinsBold(
                              fontSize: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _telefoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '(43) 99999-8888',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: AppColors.primaryBlue,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 5. Termos de Uso e Política de Privacidade (Obrigatório)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _concordaTermos
                                  ? AppColors.primaryBlue.withValues(
                                      alpha: 0.05,
                                    )
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _concordaTermos
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _concordaTermos,
                                  activeColor: AppColors.primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (v) {
                                    setState(() {
                                      _concordaTermos = v ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      children: [
                                        const Text(
                                          'Eu li e concordo com os ',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        GestureDetector(
                                          onTap: _exibirDialogoTermosDeUso,
                                          child: const Text(
                                            'Termos de Uso',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          ' e as ',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        GestureDetector(
                                          onTap:
                                              _exibirDialogoPoliticaPrivacidade,
                                          child: const Text(
                                            'Políticas de Privacidade',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          ' para prosseguir no aplicativo.',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Botão de ação "PROSSEGUIR"
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: (_isSaving || !_concordaTermos)
                                  ? null
                                  : _concluirCadastro,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                disabledBackgroundColor: Colors.grey.shade300,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'CONCLUIR E COMEÇAR',
                                      style: TextStyles.poppinsBold(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho superior no estilo Dashboard.
  Widget _buildHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 52),
      decoration: const BoxDecoration(color: AppColors.primaryBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informações Adicionais',
                style: TextStyles.poppinsBold(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Personalize sua experiência no COGITO com informações essenciais sobre você.',
              style: TextStyles.poppinsRegular(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o card seletor individual de Tipo de Renda.
  Widget _buildOpcaoTipoRenda({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required String tipoValor,
    required Color corTema,
  }) {
    final bool isSelected = _tipoRenda == tipoValor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoRenda = tipoValor;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? corTema.withValues(alpha: 0.08)
              : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? corTema : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: isSelected ? corTema : Colors.grey.shade600,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyles.poppinsBold(
                fontSize: 13,
                color: isSelected ? corTema : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: TextStyles.poppinsRegular(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
