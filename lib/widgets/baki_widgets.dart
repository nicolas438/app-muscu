import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bannière thématique style Baki pour les séances
class BakiBanner extends StatelessWidget {
  final String sessionName;
  final String? subtitle;
  final int bannerIndex;
  final VoidCallback? onTap;

  const BakiBanner({
    super.key,
    required this.sessionName,
    this.subtitle,
    this.bannerIndex = 0,
    this.onTap,
  });

  // Citations motivantes style Baki
  static const List<String> bakiQuotes = [
    "LA FORCE EST TOUT",
    "DÉPASSE TES LIMITES",
    "COMBAT JUSQU'AU BOUT",
    "DEVIENS LE PLUS FORT",
    "AUCUNE EXCUSE",
    "ÉCRASE LA FAIBLESSE",
    "LA DOULEUR EST TEMPORAIRE",
    "DEVIENS UNE LÉGENDE",
  ];

  // Patterns décoratifs pour les bannières
  static const List<List<Color>> bannerGradients = [
    [Color(0xFFDC2626), Color(0xFF7F1D1D)], // Rouge sang
    [Color(0xFFD97706), Color(0xFF92400E)], // Or combat
    [Color(0xFF7C3AED), Color(0xFF4C1D95)], // Violet puissance
    [Color(0xFF0891B2), Color(0xFF164E63)], // Cyan énergie
    [Color(0xFF059669), Color(0xFF064E3B)], // Vert endurance
    [Color(0xFFDB2777), Color(0xFF831843)], // Rose force
  ];

  @override
  Widget build(BuildContext context) {
    final gradientColors = bannerGradients[bannerIndex % bannerGradients.length];
    final quote = bakiQuotes[bannerIndex % bakiQuotes.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Pattern décoratif de fond
            Positioned.fill(
              child: CustomPaint(
                painter: _BakiPatternPainter(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            
            // Ligne diagonale style manga
            Positioned(
              right: -20,
              top: -20,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 100,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Citation en haut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      quote,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  
                  // Nom de la séance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Icône combat en bas à droite
            Positioned(
              right: 16,
              bottom: 16,
              child: Icon(
                Icons.fitness_center,
                size: 32,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter pour les patterns de fond style manga
class _BakiPatternPainter extends CustomPainter {
  final Color color;

  _BakiPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Lignes diagonales
    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget pour afficher une image de personnage Baki
class BakiCharacterImage extends StatelessWidget {
  final String imagePath;
  final double height;
  final BoxFit fit;

  const BakiCharacterImage({
    super.key,
    required this.imagePath,
    this.height = 200,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(
          imagePath,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // Placeholder si l'image n'existe pas
            return Container(
              height: height,
              color: AppColors.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image non trouvée',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// En-tête de séance avec style Baki
class BakiSessionHeader extends StatelessWidget {
  final String title;
  final String? exerciseCount;
  final Color? accentColor;

  const BakiSessionHeader({
    super.key,
    required this.title,
    this.exerciseCount,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SÉANCE',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          if (exerciseCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                exerciseCount!,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
