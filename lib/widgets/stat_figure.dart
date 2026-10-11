import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Valeur chiffrée accompagnée de son libellé, pour les rangées de statistiques.
class StatFigure extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final CrossAxisAlignment alignment;

  const StatFigure({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.text,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppText.figureL.copyWith(color: color)),
        const SizedBox(height: AppSpace.xs),
        Text(label, style: AppText.label),
      ],
    );
  }
}

/// Rangée de statistiques séparées par de fins traits verticaux.
class StatRow extends StatelessWidget {
  final List<StatFigure> figures;

  const StatRow({super.key, required this.figures});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < figures.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: AppSpace.l),
          color: AppColors.line,
        ));
      }
      children.add(Expanded(child: figures[i]));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}
