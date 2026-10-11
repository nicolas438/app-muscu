import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Surface blanche bordée, support de base des contenus groupés.
///
/// Volontairement sans ombre : la hiérarchie vient du contraste entre la
/// craie du fond et le blanc des panneaux, pas d'effets de profondeur.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color color;
  final Color borderColor;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.l),
    this.onTap,
    this.onLongPress,
    this.color = AppColors.surface,
    this.borderColor = AppColors.line,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.l);

    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
