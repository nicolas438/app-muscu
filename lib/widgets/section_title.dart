import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Titre de section, avec une action facultative alignée à droite.
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: AppText.heading)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
