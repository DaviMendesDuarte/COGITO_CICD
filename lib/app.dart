import 'package:cogito/common/constant/app_colors.dart';
import 'package:cogito/common/constant/text_styles.dart';
import 'package:cogito/features/home/home_page.dart';
import 'package:cogito/services/app_settings_controller.dart';
import 'package:flutter/material.dart';

/// Widget raiz da aplicação COGITO.
/// Configura o [MaterialApp], suporte reativo a tema escuro/claro com a fonte Poppins, tamanho de fontes e modo daltonismo.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettingsController.instance,
      builder: (context, _) {
        final settings = AppSettingsController.instance;
        final matrix = settings.daltonismoColorMatrix;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'COGITO',
          // Suporte reativo a temas Claro e Escuro com a fonte Poppins
          themeMode: settings.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: TextStyles.fontFamily,
            brightness: Brightness.light,
            primaryColor: AppColors.primaryBlue,
            scaffoldBackgroundColor: AppColors.backgroundColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: TextStyles.fontFamily,
            brightness: Brightness.dark,
            primaryColor: AppColors.primaryYellow,
            scaffoldBackgroundColor: const Color(0xFF121218),
            cardColor: const Color(0xFF1E1E2C),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryYellow,
              brightness: Brightness.dark,
            ),
          ),

          // Injeta escala de fonte e filtro de cores para daltonismo globalmente
          builder: (context, child) {
            Widget appWidget = child ?? const SizedBox.shrink();

            // Aplica o escalonamento dinâmico de texto (tamanho da letra)
            final mediaData = MediaQuery.of(context);
            appWidget = MediaQuery(
              data: mediaData.copyWith(
                textScaler: TextScaler.linear(settings.fontScale),
              ),
              child: appWidget,
            );

            // Aplica filtro de daltonismo caso esteja ativo
            if (matrix != null) {
              appWidget = ColorFiltered(
                colorFilter: ColorFilter.matrix(matrix),
                child: appWidget,
              );
            }

            return appWidget;
          },

          // Define a HomePage diretamente como tela inicial (utilizando apenas a splash screen nativa do SO)
          home: const HomePage(),
        );
      },
    );
  }
}