import 'package:cogito/common/constant/app_colors.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/material.dart';

/// Barra de navegação inferior (Bottom Navigation Bar) personalizada do aplicativo COGITO.
/// Inclui suporte a ícones de navegação azuis com traço indicador abaixo e um botão animado de ação flutuante ("+").
class AppNavigation extends StatefulWidget {
  /// Índice da aba atualmente selecionada.
  final int currentIndex;

  /// Callback disparado ao selecionar uma das abas de navegação.
  final ValueChanged<int> onTap;

  /// Callback disparado ao clicar no botão de adicionar ("+").
  final VoidCallback onAddPressed;

  const AppNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  // Dimensões do botão animado de ação ("+")
  static const double _addButtonMaxWidth = 76;
  static const double _addButtonHeight = 46;
  static const double _addButtonMaxRadius = 23;

  /// Define em quais telas o botão "+" deve aparecer (temporariamente desativado/oculto a pedido do usuário).
  bool get _isAddButtonVisible => false;

  @override
  Widget build(BuildContext context) {
    final Color navBgColor = AppColors.getCardColor(context);
    final Color selectedColor = AppColors.getPrimaryAccent(context);
    final Color unselectedColor =
        Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : AppColors.gray;

    return Container(
      decoration: BoxDecoration(
        color: navBgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Aba 0: Início (Dashboard)
                Expanded(
                  child: _buildItem(
                    icon: Icons.home_filled,
                    index: 0,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                  ),
                ),
                // Aba 1: Finanças
                Expanded(
                  child: _buildItem(
                    icon: Icons.bar_chart,
                    index: 1,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                  ),
                ),
                // Botão central de adicionar ("+") temporariamente oculto (largura e opacidade 0)
                _buildAddButton(selectedColor),
                // Aba 2: Conrado (IA / Recursos Premium)
                Expanded(
                  child: _buildItem(
                    icon: MdiIcons.crown,
                    index: 2,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                  ),
                ),
                // Aba 3: Perfil do Usuário
                Expanded(
                  child: _buildItem(
                    icon: Icons.person,
                    index: 3,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói um item de aba navegável com destaque visual azul e traço indicador se estiver selecionado.
  Widget _buildItem({
    required IconData icon,
    required int index,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    final bool isSelected = widget.currentIndex == index;
    final Color itemColor = isSelected ? selectedColor : unselectedColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTap(index),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: itemColor),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 14 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o botão animado de adição ("+").
  /// Utiliza [TweenAnimationBuilder] para suavemente animar largura, raio de borda e opacidade.
  Widget _buildAddButton(Color accentColor) {
    final double target = _isAddButtonVisible ? 1.0 : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: target, end: target),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubicEmphasized,
      builder: (context, t, child) {
        final double width = _addButtonMaxWidth * t;
        final double radius = _addButtonMaxRadius * t;

        return Opacity(
          opacity: t,
          child: Container(
            width: width,
            height: _addButtonHeight,
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: IgnorePointer(
              ignoring: t < 0.5,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onAddPressed,
                child: SizedBox(
                  width: _addButtonMaxWidth,
                  height: _addButtonHeight,
                  child: const Icon(
                    Icons.add,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
