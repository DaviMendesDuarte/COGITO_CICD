import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/features/onboarding/welcome_page.dart';
import 'package:cogito/services/app_settings_controller.dart';
import 'package:cogito/services/firebase_auth_service.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela dedicada de Configurações e Preferências do Aplicativo COGITO.
/// Acessível através do ícone de engrenagem no cabeçalho.
/// Reúne preferências de Aparência (Modo Escuro), Acessibilidade (Fonte e Daltonismo),
/// Notificações Push, Encerramento de Sessão (Sair da Conta) e Desativação (Deletar Conta).
class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  /// Instância do serviço de autenticação Firebase para Logout e Exclusão.
  final FirebaseAuthService _firebaseService = FirebaseAuthService();

  /// Confirma e realiza o encerramento da sessão do usuário (Logout).
  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Sair da Conta'),
          ],
        ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Exibe a caixa de diálogo exigindo a senha de confirmação para inativar/excluir a conta.
  /// Exibe a caixa de diálogo exigindo a confirmação para excluir a conta e os dados no Firebase.
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

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: AppColors.primaryBlue,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Configurações',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1: Aparência e Tema
                  _buildSectionCard(
                    titulo: 'Aparência',
                    icone: Icons.palette_outlined,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(
                          settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: settings.isDarkMode ? Colors.amber : AppColors.primaryBlue,
                        ),
                        title: const Text('Modo Escuro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          settings.isDarkMode ? 'Ativado (Afeta todas as caixas e superfícies)' : 'Desativado',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: settings.isDarkMode,
                        onChanged: (val) {
                          settings.setDarkMode(val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card 2: Acessibilidade
                  _buildSectionCard(
                    titulo: 'Acessibilidade',
                    icone: Icons.accessibility_new_outlined,
                    children: [
                      // Tamanho da Letra
                      Row(
                        children: [
                          const Icon(Icons.format_size, color: AppColors.primaryBlue, size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tamanho da Letra', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('Ajuste o tamanho dos textos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          DropdownButton<double>(
                            value: settings.fontScale,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 0.85, child: Text('Pequeno (85%)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 1.0, child: Text('Normal (100%)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 1.15, child: Text('Grande (115%)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 1.30, child: Text('Extra Grande (130%)', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                settings.setFontScale(val);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Filtro de Daltonismo
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, color: AppColors.primaryBlue, size: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Filtro de Daltonismo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('Ajuste de matriz de cores', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          DropdownButton<String>(
                            value: settings.daltonismoMode,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 'Desativado', child: Text('Desativado', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Protanopia', child: Text('Protanopia', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Deuteranopia', child: Text('Deuteranopia', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Tritanopia', child: Text('Tritanopia', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                settings.setDaltonismoMode(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card 3: Notificações
                  _buildSectionCard(
                    titulo: 'Notificações',
                    icone: Icons.notifications_none_outlined,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryBlue),
                        title: const Text('Notificações Push', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                          settings.pushNotifications ? 'Alertas de contas e dicas ativos' : 'Alertas pausados',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: settings.pushNotifications,
                        onChanged: (val) {
                          settings.setPushNotifications(val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card 4: Conexão do Aparelho
                  Builder(
                    builder: (context) {
                      final User? currentUser = FirebaseAuth.instance.currentUser;
                      final usuario = FirebaseFirestoreService.usuarioLogado;
                      final bool estaConectado = (currentUser != null || usuario != null);
                      final String email = currentUser?.email ?? usuario?['email'] ?? 'Nenhum e-mail vinculado';

                      return _buildSectionCard(
                        titulo: 'Conexão do Dispositivo',
                        icone: Icons.phonelink_setup_rounded,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              estaConectado ? Icons.check_circle_outline : Icons.phonelink_erase,
                              color: estaConectado ? Colors.green : Colors.orange,
                            ),
                            title: Text(
                              estaConectado ? 'Aparelho Conectado' : 'Dispositivo Desconectado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: estaConectado ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                            subtitle: Text('Sessão: $email\nStatus: ${estaConectado ? "Conta Conectada na Nuvem" : "Modo Visitante"}', style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Card 5: Gestão de Conta e Encerramento de Sessão
                  _buildSectionCard(
                    titulo: 'Gestão de Conta & Sessão',
                    icone: Icons.manage_accounts_outlined,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout, color: AppColors.primaryBlue),
                        title: const Text(
                          'Sair da Conta',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text('Encerrar sessão atual neste dispositivo'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _confirmarLogout,
                      ),
                      const Divider(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                        title: const Text(
                          'Deletar Conta',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                        ),
                        subtitle: const Text('Desativar permanentemente (Exige senha)'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                        onTap: _exibirDialogoExcluirConta,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Card 6: Sessão Debug & Testes de Notificação Firebase
                  _buildSectionCard(
                    titulo: 'Sessão Debug & Notificações',
                    icone: Icons.bug_report_outlined,
                    children: [
                      const Text(
                        'Disparar Notificações Pré-preparadas para o Firebase:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primaryOrange),
                            label: const Text('💡 Dica CONRADO'),
                            onPressed: () async {
                              final usuario = FirebaseFirestoreService.usuarioLogado;
                              final uid = (usuario?['uid'] ?? usuario?['id_cliente'] ?? 'guest').toString();
                              await FirebaseFirestoreService().criarNotificacao(
                                idCliente: uid,
                                titulo: 'Dica do CONRADO 💡',
                                mensagem: 'Você economizou R\$ 150,00 na categoria Alimentação este mês!',
                                categoria: 'IA Financeira',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notificação "Dica CONRADO" enviada ao Firebase!')),
                                );
                              }
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.amber),
                            label: const Text('⚠️ Alerta Orçamento'),
                            onPressed: () async {
                              final usuario = FirebaseFirestoreService.usuarioLogado;
                              final uid = (usuario?['uid'] ?? usuario?['id_cliente'] ?? 'guest').toString();
                              await FirebaseFirestoreService().criarNotificacao(
                                idCliente: uid,
                                titulo: 'Alerta de Orçamento ⚠️',
                                mensagem: 'Atenção: Seu envelope de Lazer atingiu 85% do limite estipulado.',
                                categoria: 'Sistema',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notificação "Alerta Orçamento" enviada ao Firebase!')),
                                );
                              }
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.emoji_events_outlined, size: 18, color: Colors.green),
                            label: const Text('🎉 Meta Concluída'),
                            onPressed: () async {
                              final usuario = FirebaseFirestoreService.usuarioLogado;
                              final uid = (usuario?['uid'] ?? usuario?['id_cliente'] ?? 'guest').toString();
                              await FirebaseFirestoreService().criarNotificacao(
                                idCliente: uid,
                                titulo: 'Meta Alcançada! 🎉',
                                mensagem: 'Parabéns! Sua caixinha "Viagem Europa" atingiu 100% da meta calculada.',
                                categoria: 'Metas',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notificação "Meta Concluída" enviada ao Firebase!')),
                                );
                              }
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.shield_outlined, size: 18, color: AppColors.primaryBlue),
                            label: const Text('🔒 Aviso Segurança'),
                            onPressed: () async {
                              final usuario = FirebaseFirestoreService.usuarioLogado;
                              final uid = (usuario?['uid'] ?? usuario?['id_cliente'] ?? 'guest').toString();
                              await FirebaseFirestoreService().criarNotificacao(
                                idCliente: uid,
                                titulo: 'Aviso de Segurança 🔒',
                                mensagem: 'Sua sessão foi sincronizada com segurança no novo dispositivo.',
                                categoria: 'Segurança',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notificação "Aviso Segurança" enviada ao Firebase!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Constrói um card de seção estilizado para agrupamento de configurações.
  Widget _buildSectionCard({
    required String titulo,
    required IconData icone,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
