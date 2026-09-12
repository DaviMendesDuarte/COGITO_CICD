import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/features/home/home_page.dart';
import 'package:cogito/features/onboarding/onboarding_page.dart';
import 'package:cogito/services/biometric_service.dart';
import 'package:cogito/services/firebase_auth_service.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tela de Splash (exibida durante a inicialização / carregamento do aplicativo).
/// Realiza a verificação de sessão ativa no Firebase e Biometria Nativa no Splash.
/// Se a conta estiver logada, pula o onboarding e leva diretamente para a [HomePage].
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// Instância dos serviços de autenticação e biometria.
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _inicializarSplash();
  }

  /// Inicializa a splash screen, verifica credenciais ativas e biometria no splash.
  Future<void> _inicializarSplash() async {
    // Aguarda 1.5 segundos para exibição da logomarca
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Verifica se já existe uma sessão ativa
    final bool temSessao = await _firebaseAuthService.verificarECarregarSessaoLogada();
    final bool usuarioLogado = temSessao || FirebaseFirestoreService.usuarioLogado != null;

    if (usuarioLogado) {
      // Carrega a preferência de Biometria no Splash
      final prefs = await SharedPreferences.getInstance();
      final bool biometriaSplashAtiva = prefs.getBool('biometria_splash_enabled') ?? false;
      final bool eDispositivoFisico = await _biometricService.isDispositivoFisico();

      // Se a biometria no splash estiver ativada e for um dispositivo físico real
      if (biometriaSplashAtiva && eDispositivoFisico) {
        final bool autenticado = await _biometricService.autenticarComImpressaoDigital(
          motivo: 'Autentique com sua biometria para abrir o COGITO',
        );

        if (!mounted) return;

        if (autenticado) {
          _navegarParaHome();
        } else {
          // Em caso de cancelamento da biometria, exibe opção para tentar novamente ou entrar
          _exibirOpcaoReautenticacao();
        }
      } else {
        // Sem biometria configurada, vai direto para a HomePage (pula onboarding)
        _navegarParaHome();
      }
    } else {
      // Usuário não logado, direciona para o onboarding
      _navegarParaOnboarding();
    }
  }

  /// Navega diretamente para a HomePage (pula o onboarding para usuários logados).
  void _navegarParaHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  /// Navega para a tela de Onboarding para novos acessos.
  void _navegarParaOnboarding() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingPage()),
      (route) => false,
    );
  }

  /// Exibe diálogo de segurança na splash caso a leitura biométrica falhe ou seja cancelada pelo usuário.
  /// Remove qualquer possibilidade de bypass, exigindo confirmação biométrica ou validação obrigatória de senha.
  void _exibirOpcaoReautenticacao() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Acesso Seguro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'A autenticação por impressão digital não foi confirmada. Para garantir a segurança de seus dados financeiros, valide sua identidade para prosseguir.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _exibirDialogoSenhaObrigatoria();
            },
            child: const Text('Entrar com Senha', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _inicializarSplash();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tentar Biometria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Exibe modal com campo de senha obrigatório para desbloquear o aplicativo quando a biometria falhar.
  void _exibirDialogoSenhaObrigatoria() {
    final TextEditingController senhaController = TextEditingController();
    bool carregando = false;
    String? erroMensagem;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (senhaDialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text('Confirme sua Senha'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Digite a senha da sua conta para desbloquear o aplicativo COGITO:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: senhaController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.password, color: AppColors.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      errorText: erroMensagem,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: carregando
                      ? null
                      : () async {
                          Navigator.pop(senhaDialogContext);
                          // Se desistir de digitar a senha, desloga e envia para o onboarding
                          FirebaseFirestoreService.deslogar();
                          await _firebaseAuthService.signOut();
                          if (mounted) _navegarParaOnboarding();
                        },
                  child: const Text('Sair da Conta', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: carregando
                      ? null
                      : () async {
                          final String senha = senhaController.text.trim();
                          if (senha.isEmpty) {
                            setDialogState(() {
                              erroMensagem = 'Informe sua senha';
                            });
                            return;
                          }

                          setDialogState(() {
                            carregando = true;
                            erroMensagem = null;
                          });

                          final dialogNav = Navigator.of(senhaDialogContext);
                          final bool senhaValida = await _firebaseAuthService.verificarSenha(senha);

                          if (!mounted) return;

                          if (senhaValida) {
                            dialogNav.pop();
                            _navegarParaHome();
                          } else {
                            setDialogState(() {
                              carregando = false;
                              erroMensagem = 'Senha incorreta. Tente novamente.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: carregando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Desbloquear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/logo/logo.png',
                  width: 230,
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 4.5,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}