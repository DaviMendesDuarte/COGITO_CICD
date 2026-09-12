import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/features/auth/register_page.dart';
import 'package:cogito/features/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de Escolha de Autenticação (AuthChoicePage).
/// Exibida APÓS o onboarding, separada dos slides de apresentação.
/// Apresenta exclusivamente as opções de Login e Cadastro com um design limpo e elegante.
class AuthChoicePage extends StatelessWidget {
  const AuthChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.primaryBlue),
      child: Scaffold(
        // Fundo com gradiente do azul primário ao escuro
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Área superior — avatar do Conrado e título
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar do Conrado com glow
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/images/conrado/conrado_hi.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.psychology,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Logo / Nome do App
                      const Text(
                        'COGITO',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtítulo descritivo
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Controle · Organização · Inteligência',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Área inferior — Botões de ação com glassmorphism
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(0),
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Indicador visual
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 28),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        // Título da seção
                        const Text(
                          'Comece agora',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2F60),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Acesse ou crie sua conta para começar a organizar suas finanças.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const Spacer(),

                        // Botão de Login (primário)
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: AppColors.primaryBlue.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'ENTRAR NA CONTA',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Botão de Cadastro (secundário)
                        SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CadastroPage()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              side: const BorderSide(color: AppColors.primaryBlue, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_rounded, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'CRIAR CONTA GRÁTIS',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Rodapé
                        Center(
                          child: Column(
                            children: [
                              // Logo da aplicação com tratamento de erro em caso de falha no carregamento da imagem
                              Image.asset(
                                'assets/images/logo/logo.png',
                                width: 36,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '3°DS 2026 • COGITO',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
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
}
