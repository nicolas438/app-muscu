import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// État vide : explique ce qui manque et propose l'action pour y remédier.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl, vertical: AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpace.l),
            Text(title, style: AppText.title, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: AppSpace.s),
              Text(
                message!,
                style: AppText.body.copyWith(color: AppColors.inkSoft),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
