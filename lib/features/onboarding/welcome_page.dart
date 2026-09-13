import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/features/auth/auth_choice_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tela de boas-vindas inicial (WelcomePage) apresentando os botões de Login e Cadastro.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.getOverlayStyleForBackground(AppColors.white),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60.0),

              // Imagem do mascot Conrado no topo
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Image.asset(
                    'assets/images/conrado/conrado_hi.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              // Título de boas-vindas
              const Text('BEM-VINDO', style: TextStyles.welcomeTitle),

              const SizedBox(height: 8.0),

              // Descrição do significado de COGITO
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Bem-vindo ao COGITO, ou Controle de Orçamentos e Gestão Inteligente, Técnico e Objetivo',
                  textAlign: TextAlign.center,
                  style: TextStyles.welcomeDescription,
                ),
              ),

              const SizedBox(height: 8.0),

              const Text('Comece o seu controle:', style: TextStyles.subtitle),

              const SizedBox(height: 24.0),

              // Botão para acao de Login
              SizedBox(
                height: 50,
                width: 280,
                child: ElevatedButton(
                  onPressed: () {
                    // Navega diretamente para a AuthChoicePage (tela separada de escolha)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthChoicePage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(67),
                    ),
                  ),
                  child: const Text('Começar', style: TextStyles.buttonPrimary),
                ),
              ),

              const Spacer(),

              // Rodapé com o logotipo do COGITO e identificador da turma/desenvolvimento
              Image.asset('assets/images/logo/logo.png', width: 50),

              const SizedBox(height: 8.0),

              const Text('3°DS 2026', style: TextStyles.footer),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
