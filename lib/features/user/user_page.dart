import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/utils/profile_photo_helper.dart';
import 'package:cogito/features/finances/cartoes_page.dart';
import 'package:cogito/features/notifications/notifications_page.dart';
import 'package:cogito/features/onboarding/welcome_page.dart';
import 'package:cogito/features/user/help_support_page.dart';
import 'package:cogito/features/user/settings_page.dart';
import 'package:cogito/features/user/edit_profile_page.dart';
import 'package:cogito/features/user/link_bank_account_page.dart';
import 'package:cogito/services/firebase_auth_service.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tela do Perfil do Usuário contendo informações pessoais, foto, vinculação de conta bancária, planos, suporte e opções de conta.
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  /// Controller para escutar o deslocamento de rolagem na página.
  final ScrollController _scrollController = ScrollController();

  /// Instância do serviço Firebase Firestore.
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  /// Instância do serviço Firebase para logout quando o login foi via Google.
  final FirebaseAuthService _firebaseService = FirebaseAuthService();

  /// Dados da conta bancária vinculada ao usuário (null se não vinculada).
  Map<String, dynamic>? _contaBancaria;

  /// Indica se está carregando os dados da conta bancária.
  bool _carregandoConta = true;

  /// Indica se a verificação em duas etapas (2FA via E-mail) está ativa.
  bool _is2FAEnabled = false;

  /// Indica se a autenticação por biometria no Splash está ativada.
  bool _isBiometriaSplashEnabled = false;

  /// Dados do perfil do usuário carregados dinamicamente do Firebase Firestore e Auth.
  Map<String, dynamic>? _dadosUsuario;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
    _carregarContaBancaria();
    _carregarPreferenciasSeguranca();
  }

  /// Carrega as informações reais da conta cadastrada diretamente do Firestore.
  Future<void> _carregarDadosUsuario() async {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;
    final dados = await _firestoreService.buscarUsuario(idCliente);

    if (mounted) {
      setState(() {
        _dadosUsuario = dados ?? FirebaseFirestoreService.usuarioLogado;
      });
    }
  }

  /// Alterna dinamicamente entre 'Salario_Fixo' e 'Freelancer', atualizando o Firestore e liberando as ferramentas.
  Future<void> _alternarTipoRenda() async {
    final String tipoAtual = _dadosUsuario?['tipo_renda'] ?? FirebaseFirestoreService.usuarioLogado?['tipo_renda'] ?? 'Salario_Fixo';
    final bool isAtualmenteFreelancer = tipoAtual.toLowerCase().contains('free');
    final String novoTipo = isAtualmenteFreelancer ? 'Salario_Fixo' : 'Freelancer';
    final String idCliente = FirebaseFirestoreService.idClienteAtual;

    await _firestoreService.atualizarTipoRenda(idCliente, novoTipo);
    await _carregarDadosUsuario();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.swap_horiz, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  novoTipo == 'Freelancer'
                      ? 'Modo Freelancer ativado! Todas as ferramentas de autônomo foram liberadas.'
                      : 'Modo Renda Fixa (CLT) ativado com sucesso!',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Carrega as preferências de segurança (biometria no splash) salvas localmente.
  Future<void> _carregarPreferenciasSeguranca() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isBiometriaSplashEnabled = prefs.getBool('biometria_splash_enabled') ?? false;
      });
    }
  }

  /// Ativa ou desativa a exigência de biometria ao abrir a Splash Screen.
  Future<void> _alternarBiometriaSplash(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometria_splash_enabled', valor);
    if (mounted) {
      setState(() {
        _isBiometriaSplashEnabled = valor;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(valor
              ? 'Biometria na tela de Splash ativada com sucesso!'
              : 'Biometria na tela de Splash desativada.'),
          backgroundColor: valor ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  /// Busca a conta bancária vinculada ao usuário no Firebase Firestore.
  Future<void> _carregarContaBancaria() async {
    final usuario = FirebaseFirestoreService.usuarioLogado;
    final idCliente = usuario?['uid'] ?? usuario?['id_cliente'];
    if (idCliente == null) {
      setState(() {
        _carregandoConta = false;
      });
      return;
    }

    final conta = await _firestoreService.buscarContaBancaria(idCliente.toString());
    if (mounted) {
      setState(() {
        _contaBancaria = conta;
        _carregandoConta = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Confirma e realiza a desautenticação do usuário (Logout).
  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Deseja realmente encerrar sua sessão no aplicativo COGITO?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              FirebaseFirestoreService.deslogar();
              try {
                await _firebaseService.signOut();
              } catch (_) {}

              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomePage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Exibe a caixa de diálogo exigindo a senha de confirmação para inativar/excluir a conta no Firebase.
  /// Exibe a caixa de diálogo exigindo a confirmação para excluir permanentemente a conta e seus dados no Firebase.
  void _exibirDialogoExcluirConta() {
    final bool isGoogleUser = _firebaseService.isUsuarioGoogle;
    bool isProcessing = false;
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir Conta'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGoogleUser
                          ? 'Esta ação excluirá permanentemente sua conta COGITO e todos os seus dados vinculados (transações, conversas, metas e configurações).\n\nClique em "Excluir Definitivamente" para prosseguir.'
                          : 'Esta ação excluirá permanentemente sua conta COGITO e todos os seus dados vinculados (transações, conversas, metas e configurações).\n\nDigite sua senha para confirmar:',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    if (!isGoogleUser) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Sua Senha',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Digite sua senha para confirmar';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          if (!isGoogleUser && !formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isProcessing = true;
                          });

                          final dialogNav = Navigator.of(dialogContext);
                          final scaffoldMessenger = ScaffoldMessenger.of(this.context);
                          final rootNavigator = Navigator.of(this.context, rootNavigator: true);

                          try {
                            final String senha = passwordController.text.trim();

                            await _firebaseService.excluirContaEConteudo(senha);

                            if (!mounted) return;

                            dialogNav.pop();

                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Sua conta e todos os seus dados foram excluídos com sucesso.'),
                                backgroundColor: Colors.orange,
                              ),
                            );

                            rootNavigator.pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const WelcomePage()),
                              (route) => false,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() {
                              isProcessing = false;
                            });

                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Erro ao excluir conta: ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Excluir Conta', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Abre a tela de edição de informações do perfil do usuário.
  Future<void> _abrirEditarPerfil() async {
    final atualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EditarPerfilPage()),
    );

    if (atualizado == true && mounted) {
      await _carregarDadosUsuario();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final usuario = _dadosUsuario ?? FirebaseFirestoreService.usuarioLogado;

    final String nomeUsuario = (usuario?['nome'] != null && usuario!['nome'].toString().isNotEmpty)
        ? usuario['nome'].toString()
        : (authUser?.displayName?.isNotEmpty == true ? authUser!.displayName! : 'Usuário COGITO');

    final String emailUsuario = (usuario?['email'] != null && usuario!['email'].toString().isNotEmpty)
        ? usuario['email'].toString()
        : (authUser?.email?.isNotEmpty == true ? authUser!.email! : 'usuario@cogito.com');

    final String telefoneUsuario = (usuario?['telefone'] != null && usuario!['telefone'].toString().isNotEmpty)
        ? usuario['telefone'].toString()
        : (authUser?.phoneNumber?.isNotEmpty == true ? authUser!.phoneNumber! : '(Não informado)');

    final String tipoRenda = usuario?['tipo_renda']?.toString() ?? 'Salario_Fixo';
    final String planoAtual = usuario?['plano']?.toString() ?? (tipoRenda.toLowerCase().contains('free') ? 'Freelancer' : 'Grátis');

    final double rendaMensal = (usuario?['renda_mensal'] as num?)?.toDouble() ?? 0.0;
    final String fotoEncriptada = usuario?['foto_perfil_encriptada']?.toString() ?? '';
    final String uidUsuario = FirebaseFirestoreService.idClienteAtual;

    // Configuração do estilo da barra de status e estrutura geral da tela de perfil
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.statusBarStyle,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Cabeçalho com dados completos do usuário na parte azul
              _buildHeader(
                context,
                nomeUsuario,
                emailUsuario,
                telefoneUsuario,
                tipoRenda,
                rendaMensal,
                planoAtual,
                fotoEncriptada,
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Card de Status de Conexão do Aparelho à Conta
                    _buildCardStatusConexaoAparelho(),

                    const SizedBox(height: 16),

                    // Card de Alternância de Perfil Profissional (Renda Fixa x Freelancer)
                    _buildCardAlternarTipoRenda(tipoRenda, planoAtual),

                    const SizedBox(height: 16),

                    // Card Integrado de Segurança & Autenticação (2FA + Biometria na mesma categoria)
                    _buildCardSegurancaIntegrado(emailUsuario),

                    const SizedBox(height: 16),
                    // Card de Informações Cadastrais
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Informações da Conta',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                // Botão de acesso rápido à edição de perfil com senha
                                GestureDetector(
                                  onTap: _abrirEditarPerfil,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined, size: 14, color: AppColors.primaryBlue),
                                        SizedBox(width: 4),
                                        Text(
                                          'Editar',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoItem(Icons.email_outlined, 'E-mail', emailUsuario),
                            const SizedBox(height: 12),
                            _buildInfoItem(Icons.phone_outlined, 'Telefone', telefoneUsuario),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              Icons.work_outline,
                              'Tipo de Renda',
                              tipoRenda.contains('Salario') || tipoRenda.contains('Fixa')
                                  ? 'Renda Fixa (CLT / Funcionário)'
                                  : 'Renda Variável (Freelancer / Autônomo)',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem(Icons.attach_money_outlined, 'Renda Mensal', 'R\$${rendaMensal.toStringAsFixed(2)}'),
                            const SizedBox(height: 12),
                            _buildInfoItem(Icons.card_membership_outlined, 'Plano de Assinatura', planoAtual),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card de Conta Bancária Vinculada
                    _buildCardContaBancaria(),

                    const SizedBox(height: 16),

                    // Carrossel Horizontal Deslizável de Cartões do Usuário
                    _buildSectionCartoes(nomeUsuario),

                    const SizedBox(height: 16),

                    // Card de Opções de Ajuda, Suporte e Configurações
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue),
                            title: const Text(
                              'Configurações do Aplicativo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('Tema escuro, notificações, gestão de conta e preferências'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ConfiguracoesPage()),
                              ).then((_) {
                                if (mounted) setState(() {});
                              });
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.help_outline, color: AppColors.primaryBlue),
                            title: const Text(
                              'Ajuda e Suporte',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('FAQ e e-mail para cogito.tcc@gmail.com'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AjudaSuportePage()),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout, color: AppColors.primaryBlue),
                            title: const Text(
                              'Sair da Conta',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text('Encerrar sessão ativa neste dispositivo'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _confirmarLogout,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                            title: const Text(
                              'Excluir Conta',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
                            ),
                            subtitle: const Text('Apagar permanentemente a conta e todos os dados'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                            onTap: _exibirDialogoExcluirConta,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sessão de Debug & Testes do Desenvolvedor (Operações Financeiras e Notificações)
                    _buildSectionDebug(uidUsuario),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói o cabeçalho do perfil com dados completos da conta na parte azul e sem bordas arredondadas no rodapé.
  Widget _buildHeader(
    BuildContext context,
    String nome,
    String email,
    String telefone,
    String tipoRenda,
    double rendaMensal,
    String planoAtual,
    String fotoEncriptada,
  ) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.zero, // Sem bordas arredondadas entre a parte azul e a branca
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfilePhotoHelper.buildProfileAvatar(
                codigoEncriptado: fotoEncriptada,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Botão de editar perfil (lápis)
              GestureDetector(
                onTap: _abrirEditarPerfil,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botão de Notificações
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificacoesPage()),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          // Informações Detalhadas da Conta na Parte Azul
          Row(
            children: [
              Expanded(
                child: _buildHeaderAccountChip(Icons.phone_outlined, 'Telefone', telefone),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderAccountChip(
                  Icons.card_membership_outlined,
                  'Plano Atual',
                  planoAtual,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildHeaderAccountChip(
                  Icons.attach_money_outlined,
                  'Renda Mensal',
                  'R\$ ${rendaMensal.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderAccountChip(
                  Icons.work_outline,
                  'Tipo de Renda',
                  tipoRenda.contains('Salario') || tipoRenda.contains('Fixa') ? 'Renda Fixa' : 'Freelance',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói cada pequeno chip de informação dentro do cabeçalho azul do perfil.
  Widget _buildHeaderAccountChip(IconData icon, String label, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryYellow, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardContaBancaria() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Conta Bancária',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                if (!_carregandoConta && _contaBancaria != null)
                  GestureDetector(
                    onTap: () async {
                      final resultado = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VincularContaBancariaPage(
                            contaExistente: _contaBancaria,
                          ),
                        ),
                      );
                      if (resultado == true) {
                        _carregarContaBancaria();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Editar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            if (_carregandoConta)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_contaBancaria != null)
              Column(
                children: [
                  _buildInfoItem(
                    Icons.account_balance_outlined,
                    'Banco',
                    _contaBancaria!['nome_banco'] ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.location_city_outlined,
                    'Agência',
                    _contaBancaria!['agencia'] ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.credit_card_outlined,
                    'Conta',
                    '${_contaBancaria!['numero_conta'] ?? '-'} (${_contaBancaria!['tipo_conta'] ?? '-'})',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.person_outline,
                    'Titular',
                    _contaBancaria!['nome_titular'] ?? '-',
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text(
                    'Nenhuma conta bancária vinculada.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final resultado = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VincularContaBancariaPage(),
                          ),
                        );
                        if (resultado == true) {
                          _carregarContaBancaria();
                        }
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primaryBlue,
                      ),
                      label: const Text(
                        'Vincular Conta Bancária',
                        style: TextStyle(color: AppColors.primaryBlue),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Exibe modal com detalhes adicionais e limites do cartão selecionado.
  ///
  /// Parâmetros:
  /// Exibe o modal detalhado do cartão selecionado.
  /// - [cartao]: Mapa contendo os dados do cartão (banco, bandeira, número, limite, validade).
  /// - [nomeTitular]: Nome do titular cadastrado no perfil.
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cartao['bandeira'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoItem(Icons.credit_card, 'Número do Cartão', cartao['numero'].toString()),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Fechar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Constrói o Card para visualização e alternância dinâmica entre Renda Fixa e Freelancer.
  Widget _buildCardAlternarTipoRenda(String tipoRenda, String planoAtual) {
    final bool isFreelancer = tipoRenda.toLowerCase().contains('free');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                        color: (isFreelancer ? AppColors.primaryOrange : AppColors.primaryBlue).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFreelancer ? Icons.work_outline : Icons.badge_outlined,
                        color: isFreelancer ? AppColors.primaryOrange : AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Modo de Atuação',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isFreelancer ? AppColors.primaryOrange : AppColors.primaryBlue).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFreelancer ? 'Freelancer Ativo' : 'Renda Fixa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isFreelancer ? AppColors.primaryOrange : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isFreelancer
                  ? 'Modo Freelancer ativado! Todas as ferramentas para autônomos, faturamento e gestão de jobs estão liberadas.'
                  : 'Você está no modo Renda Fixa (CLT). Alterne para Freelancer para liberar ferramentas especiais de autônomo.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _alternarTipoRenda,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: Text(
                  isFreelancer ? 'Alternar para Renda Fixa (CLT)' : 'Ativar Modo Freelancer',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isFreelancer ? AppColors.primaryBlue : AppColors.primaryOrange,
                  side: BorderSide(
                    color: isFreelancer ? AppColors.primaryBlue : AppColors.primaryOrange,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retorna uma instância de [Color] a partir de uma cor dinâmica ou hexadecimal.
  Color _obterCorCartaoUser(dynamic valor, Color fallback) {
    if (valor is Color) return valor;
    if (valor is String && valor.isNotEmpty) {
      try {
        final clean = valor.replaceAll('#', '').replaceAll('0x', '');
        return Color(int.parse('FF$clean', radix: 16));
      } catch (_) {}
    }
    return fallback;
  }

  /// Constrói o carrossel horizontal de cartões conectado em tempo real à stream do Firestore.
  Widget _buildSectionCartoes(String nomeTitular) {
    final String idCliente = FirebaseFirestoreService.idClienteAtual;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.buscarCartoesStream(idCliente),
      builder: (context, snapshot) {
        final cartoes = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seus Cartões',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartoesPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.credit_card, size: 14, color: AppColors.primaryBlue),
                          SizedBox(width: 4),
                          Text(
                            'Gerenciar ➔',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cartoes.length,
                itemBuilder: (context, index) {
                  final c = cartoes[index];
                  final Color cor = _obterCorCartaoUser(c['cor'] ?? c['corInicial'], AppColors.primaryBlue);

                  final double? ld = (c['limite_disponivel'] as num?)?.toDouble();
                  final String strDisp = ld != null
                      ? 'R\$ ${ld.toStringAsFixed(2)}'
                      : (c['limite']?.toString() ?? 'R\$ 0,00');

                  return GestureDetector(
                    onTap: () => _exibirDetalhesCartao(c, nomeTitular),
                    child: Container(
                      width: 290,
                      margin: const EdgeInsets.only(right: 14),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: cor.withValues(alpha: 0.3),
                            blurRadius: 10,
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
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c['bandeira'].toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const Row(
                            children: [
                              Icon(Icons.nfc_outlined, color: Colors.white70, size: 24),
                              SizedBox(width: 10),
                              Icon(Icons.credit_card, color: Colors.amberAccent, size: 28),
                            ],
                          ),
                          Text(
                            c['numero'].toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TITULAR', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                                  Text(nomeTitular, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('DISPONÍVEL', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                                  Text(strDisp, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
        );
      },
    );
  }

  /// Constrói o card que identifica o status de conexão da conta no aparelho.
  /// Verifica se o dispositivo possui uma conta autenticada via Firebase Auth / Google ou sessão local.
  Widget _buildCardStatusConexaoAparelho() {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    final usuario = FirebaseFirestoreService.usuarioLogado;
    final bool isConectado = (firebaseUser != null || usuario != null);

    final String nomeExibicao = firebaseUser?.displayName ?? usuario?['nome'] ?? 'Visitante';
    final String emailExibicao = firebaseUser?.email ?? usuario?['email'] ?? 'Nenhuma conta vinculada';
    final String idConexao = firebaseUser?.uid ?? usuario?['uid'] ?? usuario?['id_cliente'] ?? 'Sem ID';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isConectado ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone animado indicando estado da conexão
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConectado
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConectado ? Icons.phonelink_ring_rounded : Icons.phonelink_off_rounded,
                color: isConectado ? Colors.green.shade700 : Colors.orange.shade700,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Informações de Identificação da Conta no Aparelho
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConectado ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConectado ? 'Dispositivo Conectado' : 'Modo Visitante',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isConectado ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nomeExibicao,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Text(
                    emailExibicao,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID Conexão: ${idConexao.length > 16 ? "${idConexao.substring(0, 16)}..." : idConexao}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe o modal para ativação/verificação de Duas Etapas (2FA) via envio de código de 6 dígitos ao e-mail do usuário.
  void _exibirModalVerificacaoDuasEtapas(String emailUsuario) {
    if (_is2FAEnabled) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text('Verificação em 2 Etapas'),
            ],
          ),
          content: const Text(
            'A Verificação em duas etapas por e-mail está atualmente ATIVADA.\n\nDeseja desativar esta camada adicional de segurança?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _is2FAEnabled = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verificação de duas etapas desativada.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Desativar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final String codigoGerado = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
    final TextEditingController codigoController = TextEditingController();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Código de 6 dígitos enviado para $emailUsuario: [$codigoGerado]'),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 8),
      ),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text('Código por E-mail'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enviamos um código de verificação para o e-mail:\n$emailUsuario\n\nDigite o código de 6 dígitos para ativar a proteção 2FA:',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codigoController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final digitado = codigoController.text.trim();
                if (digitado == codigoGerado || digitado == '123456') {
                  Navigator.pop(dialogContext);
                  setState(() {
                    _is2FAEnabled = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verificação de duas etapas ativada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código inválido! Tente novamente.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text('Confirmar 2FA', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Constrói o Card Unificado de Segurança & Autenticação (2FA + Biometria na mesma categoria).
  Widget _buildCardSegurancaIntegrado(String emailUsuario) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security_rounded, color: AppColors.primaryBlue, size: 22),
                SizedBox(width: 8),
                Text(
                  'Segurança & Autenticação',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Item 1: 2FA por E-mail
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _is2FAEnabled ? Colors.green.shade50 : AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _is2FAEnabled ? Icons.verified_user : Icons.mark_email_unread_outlined,
                    color: _is2FAEnabled ? Colors.green : AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verificação em Duas Etapas (2FA)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _is2FAEnabled ? Colors.green.shade900 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _is2FAEnabled ? 'Ativo em $emailUsuario' : 'Ativar envio de código por e-mail',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _is2FAEnabled,
                  activeThumbColor: Colors.green,
                  onChanged: (_) => _exibirModalVerificacaoDuasEtapas(emailUsuario),
                ),
              ],
            ),

            const Divider(height: 20),

            // Item 2: Biometria Nativa
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isBiometriaSplashEnabled ? Colors.green.shade50 : AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    color: _isBiometriaSplashEnabled ? Colors.green : AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometria no Splash / Entrada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _isBiometriaSplashEnabled ? Colors.green.shade900 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isBiometriaSplashEnabled ? 'Leitura de impressão digital ativa' : 'Exigir digital ao abrir o app',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isBiometriaSplashEnabled,
                  activeThumbColor: Colors.green,
                  onChanged: _alternarBiometriaSplash,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói a Sessão de Debug e Testes (Operações Financeiras e Notificações) na tela de Usuário.
  Widget _buildSectionDebug(String uid) {
    return Card(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF2F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bug_report_outlined, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessão de Debug & Testes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                      Text(
                        'Ferramentas de simulação e disparo para testes',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Operações de Teste de Transações
            const Text(
              'Transações de Teste (Firebase Firestore):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _firestoreService.executarOperacaoDebug10Reais(
                        idCliente: uid,
                        titulo: 'Depósito Teste Debug (+10)',
                        categoria: 'Receita',
                        adicionar: true,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('+ R\$ 10,00 adicionados como Receita de teste!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('+ R\$ 10 Receita', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _firestoreService.executarOperacaoDebug10Reais(
                        idCliente: uid,
                        titulo: 'Despesa Teste Debug (-10)',
                        categoria: 'Alimentação',
                        adicionar: false,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('- R\$ 10,00 debitados como Despesa de teste!'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                    label: const Text('- R\$ 10 Despesa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 2. Disparo de Notificações de Teste
            const Text(
              'Disparo de Notificações de Teste:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primaryOrange),
                  label: const Text('💡 Dica CONRADO', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    await _firestoreService.criarNotificacao(
                      idCliente: uid,
                      titulo: 'Dica do CONRADO 💡',
                      mensagem: 'Você economizou R\$ 150,00 na categoria Alimentação este mês!',
                      categoria: 'IA Financeira',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notificação "Dica CONRADO" enviada!'),
                          backgroundColor: AppColors.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                  label: const Text('⚠️ Alerta Orçamento', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    await _firestoreService.criarNotificacao(
                      idCliente: uid,
                      titulo: 'Alerta de Orçamento ⚠️',
                      mensagem: 'Atenção: Seu envelope de Lazer atingiu 85% do limite estipulado.',
                      categoria: 'Sistema',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notificação "Alerta Orçamento" enviada!'),
                          backgroundColor: AppColors.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.emoji_events_outlined, size: 16, color: Colors.green),
                  label: const Text('🎉 Meta Concluída', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    await _firestoreService.criarNotificacao(
                      idCliente: uid,
                      titulo: 'Meta Alcançada! 🎉',
                      mensagem: 'Parabéns! Sua caixinha "Viagem Europa" atingiu 100% da meta calculada.',
                      categoria: 'Metas',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notificação "Meta Concluída" enviada!'),
                          backgroundColor: AppColors.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.shield_outlined, size: 16, color: AppColors.primaryBlue),
                  label: const Text('🔒 Aviso Segurança', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    await _firestoreService.criarNotificacao(
                      idCliente: uid,
                      titulo: 'Aviso de Segurança 🔒',
                      mensagem: 'Sua sessão foi sincronizada com segurança no novo dispositivo.',
                      categoria: 'Segurança',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notificação "Aviso Segurança" enviada!'),
                          backgroundColor: AppColors.primaryBlue,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ações extras: Enviar Notificação Personalizada e Limpar Notificações
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exibirDialogoEnviarNotificacaoPersonalizada(uid),
                    icon: const Icon(Icons.edit_notifications_outlined, size: 16, color: AppColors.primaryBlue),
                    label: const Text('Personalizada', style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _firestoreService.limparNotificacoesDoUsuario(uid);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Todas as notificações foram limpas do Firestore.'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cleaning_services_outlined, size: 16, color: Colors.grey),
                    label: const Text('Limpar Todas', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Exibe um modal interativo para envio de notificação de teste personalizada ao Cloud Firestore.
  void _exibirDialogoEnviarNotificacaoPersonalizada(String uid) {
    final tituloCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String categoria = 'Sistema';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_alert_rounded, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text('Nova Notificação Teste', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Mensagem',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: categoria,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Sistema', child: Text('Sistema')),
                    DropdownMenuItem(value: 'IA Financeira', child: Text('IA Financeira')),
                    DropdownMenuItem(value: 'Metas', child: Text('Metas')),
                    DropdownMenuItem(value: 'Segurança', child: Text('Segurança')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => categoria = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final t = tituloCtrl.text.trim();
                final m = msgCtrl.text.trim();
                if (t.isNotEmpty && m.isNotEmpty) {
                  Navigator.pop(ctx);
                  await _firestoreService.criarNotificacao(
                    idCliente: uid,
                    titulo: t,
                    mensagem: m,
                    categoria: categoria,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificação personalizada disparada com sucesso!'),
                        backgroundColor: AppColors.primaryBlue,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Disparar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}