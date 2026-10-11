import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pastille en forme de disque de musculation (avec son trou central),
/// utilisée pour identifier la couleur d'une séance.
class PlateMarker extends StatelessWidget {
  final Color color;
  final double size;

  /// Couleur du trou central : celle du fond sur lequel la pastille est posée.
  final Color holeColor;

  const PlateMarker({
    super.key,
    required this.color,
    this.size = 14,
    this.holeColor = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.32,
        height: size * 0.32,
        decoration: BoxDecoration(color: holeColor, shape: BoxShape.circle),
      ),
    );
  }
}
