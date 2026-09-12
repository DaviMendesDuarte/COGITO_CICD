import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central de tokens de cores do aplicativo COGITO.
/// Define paletas primárias, secundárias e métodos auxiliares para adequação visual.
class AppColors {
  // Construtor privado para impedir instanciação da classe utilitária.
  AppColors._();

  // Cores de marca principais
  static const Color primaryBlue = Color(0xFF142251);
  static const Color primaryOrange = Color(0xFFF5891D);
  static const Color primaryYellow = Color(0xFFFCAA17);

  // Cores secundárias e neutras
  static const Color secundaryBlue = Color(0xFF232E5C);

  /// Cor principal para textos legíveis (#1D1D1D) com alto contraste e elegância
  static const Color textPrimary = Color(0xFF1D1D1D);

  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFB0B0B0);

  // Cor padrão do plano de fundo da aplicação
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Lista com as cores primárias do sistema
  static const List<Color> primaryColors = [
    primaryBlue,
    primaryOrange,
    primaryYellow,
  ];

  /// Verifica se a cor fornecida pertence à lista de cores primárias.
  static bool isPrimaryColor(Color color) {
    return primaryColors.contains(color);
  }

  /// Retorna a cor de card dinâmica de acordo com o tema ativo (Escuro ou Claro).
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E2C)
        : Colors.white;
  }

  /// Retorna a cor de fundo principal de tela de acordo com o tema ativo.
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF12121A)
        : backgroundColor;
  }

  /// Retorna a cor de destaque principal dinâmica (Azul no modo Claro e Amarelo no modo Escuro).
  static Color getPrimaryAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryYellow
        : primaryBlue;
  }

  /// Retorna a cor primária de texto ajustada ao contraste do tema.
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : textPrimary;
  }

  /// Estilo fixo e padronizado para a barra de status do sistema: fundo de cor azul primária (#142251) e ícones brancos.
  static const SystemUiOverlayStyle statusBarStyle = SystemUiOverlayStyle(
    statusBarColor: primaryBlue, // Fundo azul sólido permanente
    statusBarIconBrightness: Brightness.light, // Ícones brancos no Android
    statusBarBrightness: Brightness.dark, // Ícones brancos no iOS
  );

  /// Retorna sempre o estilo com fundo de cor azul primária e ícones brancos para a status bar.
  static SystemUiOverlayStyle getOverlayStyleForBackground([Color? color]) {
    return statusBarStyle;
  }
}
