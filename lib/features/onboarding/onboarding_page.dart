import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/button_styles.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/features/auth/auth_choice_page.dart';
import 'package:cogito/features/home/home_page.dart';
import 'package:cogito/services/firebase_auth_service.dart';
import 'package:cogito/services/firebase_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Tela de Onboarding (apresentação dos recursos do aplicativo em carrossel/PageView).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  /// Controller para gerenciar a transição e a posição das páginas no [PageView].
  final PageController _controller = PageController();

  /// Total de páginas/slides do onboarding.
  static const int pageCount = 4;

  /// Flag para identificar se o usuário atingiu a última página do onboarding.
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    _verificarContaLogada();
  }

  /// Identifica se já existe uma conta autenticada no aparelho e redireciona direto para a HomePage.
  Future<void> _verificarContaLogada() async {
    final bool temSessao = await FirebaseAuthService()
        .verificarECarregarSessaoLogada();
    if (temSessao || FirebaseFirestoreService.usuarioLogado != null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Navega para a [AuthChoicePage] ao concluir o onboarding.
  /// A AuthChoicePage é uma tela limpa dedicada exclusivamente à escolha entre Login e Cadastro.
  void _finalizarOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthChoicePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.white),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() {
              _isLastPage = (index == pageCount - 1);
            });
          },
          children: [
            // Slide 1: Boas-vindas e introdução ao COGITO
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/conrado/conrado_hi.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32.0),
                  const Text('BEM-VINDO', style: TextStyles.welcomeTitle),
                  const SizedBox(height: 12.0),
                  const Text(
                    'Conheça o COGITO, sistema de Controle de Orçamentos e Gestão Inteligente, Técnico e Objetivo.',
                    textAlign: TextAlign.center,
                    style: TextStyles.welcomeDescription,
                  ),
                ],
              ),
            ),

            // Slide 2: O que é o COGITO
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/conrado/conrado_hi.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32.0),
                  const Text(
                    'O QUE É O COGITO?',
                    style: TextStyles.welcomeTitle,
                  ),
                  const SizedBox(height: 12.0),
                  const Text(
                    'O COGITO é uma plataforma de gestão financeira voltada à organização e ao controle de finanças pessoais e empresariais.',
                    textAlign: TextAlign.center,
                    style: TextStyles.welcomeDescription,
                  ),
                ],
              ),
            ),

            // Slide 3: Apresentação do Conrado (assistente virtual)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/conrado/conrado_hi.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32.0),
                  const Text('CONRADO', style: TextStyles.welcomeTitle),
                  const SizedBox(height: 12.0),
                  const Text(
                    'O CONRADO é o assistente virtual do COGITO, responsável por fornecer dicas e sugestões para auxiliar o usuário no controle financeiro.',
                    textAlign: TextAlign.center,
                    style: TextStyles.welcomeDescription,
                  ),
                ],
              ),
            ),

            // Slide 4: Conclusão do Onboarding
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/conrado/conrado_hi.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32.0),
                  const Text('TUDO PRONTO!', style: TextStyles.welcomeTitle),
                  const SizedBox(height: 12.0),
                  const Text(
                    'Agora que você já conhece o COGITO, crie sua conta ou faça login para começar a gerenciar seus gastos.',
                    textAlign: TextAlign.center,
                    style: TextStyles.welcomeDescription,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            color: AppColors.white,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Indicador visual de página (bolinhas / WormEffect)
                Positioned(
                  top: 10,
                  child: SmoothPageIndicator(
                    controller: _controller,
                    count: pageCount,
                    effect: const WormEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      spacing: 8,
                      dotColor: Colors.grey,
                      activeDotColor: AppColors.primaryBlue,
                    ),
                  ),
                ),

                // Botões de navegação ("PULAR" e "PRÓXIMO" / "COMEÇAR")
                Positioned(
                  bottom: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botão Pular (avança direto para a tela de Login/Cadastro)
                      SizedBox(
                        height: 50,
                        width: 130,
                        child: OutlinedButton(
                          onPressed: _finalizarOnboarding,
                          style: ButtonStyles.secondary,
                          child: const Text(
                            'PULAR',
                            style: TextStyles.buttonSecondary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Botão Próximo / Começar
                      SizedBox(
                        height: 50,
                        width: 130,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_isLastPage) {
                              _finalizarOnboarding();
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ButtonStyles.primary,
                          child: Text(
                            _isLastPage ? 'COMEÇAR' : 'PRÓXIMO',
                            style: TextStyles.buttonPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
