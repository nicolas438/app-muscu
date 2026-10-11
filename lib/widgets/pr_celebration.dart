import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PRCelebrationScreen extends StatefulWidget {
  final String exerciseName;
  final double newPR;
  final double? oldPR;
  final VoidCallback onComplete;
  final VoidCallback? onSkipAll;
  final int currentPRIndex;
  final int totalPRs;

  const PRCelebrationScreen({
    super.key,
    required this.exerciseName,
    required this.newPR,
    this.oldPR,
    required this.onComplete,
    this.onSkipAll,
    this.currentPRIndex = 1,
    this.totalPRs = 1,
  });

  @override
  State<PRCelebrationScreen> createState() => _PRCelebrationScreenState();
}

class _PRCelebrationScreenState extends State<PRCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _auraController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _shakeController;
  late AnimationController _powerUpController;

  late Animation<double> _auraScale;
  late Animation<double> _auraOpacity;
  late Animation<double> _textScale;
  late Animation<double> _textOpacity;
  late Animation<double> _shakeAnimation;
  late Animation<double> _powerUpScale;
  late Animation<Color?> _colorAnimation;

  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateParticles();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Aura pulsing animation
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _auraScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    _auraOpacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.elasticOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Screen shake
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Power up scale animation
    _powerUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _powerUpScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _powerUpController, curve: Curves.easeOutBack),
    );

    _colorAnimation = ColorTween(
      begin: AppColors.warning,
      end: const Color(0xFFFFD700), // Gold
    ).animate(_powerUpController);
  }

  void _generateParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble() * 400 - 200,
        y: _random.nextDouble() * 800 - 400,
        size: _random.nextDouble() * 8 + 2,
        speed: _random.nextDouble() * 2 + 1,
        angle: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  void _startAnimationSequence() async {
    // Start power up
    _powerUpController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Start shake
    _shakeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Start aura pulsing (loop)
    _auraController.repeat(reverse: true);
    
    // Start particles
    _particleController.repeat();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Show text
    _textController.forward();
  }

  @override
  void dispose() {
    _auraController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _shakeController.dispose();
    _powerUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _auraController,
          _textController,
          _particleController,
          _shakeController,
          _powerUpController,
        ]),
        builder: (context, child) {
          final shakeOffset = _shakeController.isAnimating
              ? Offset(
                  sin(_shakeController.value * pi * 10) * _shakeAnimation.value,
                  cos(_shakeController.value * pi * 10) * _shakeAnimation.value,
                )
              : Offset.zero;

          return Transform.translate(
            offset: shakeOffset,
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        (_colorAnimation.value ?? AppColors.warning).withValues(alpha: 0.3),
                        Colors.black,
                      ],
                    ),
                  ),
                ),

                // Skip all button (top right)
                if (widget.onSkipAll != null && widget.totalPRs > 1)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Transform.scale(
                      scale: _textScale.value,
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: GestureDetector(
                          onTap: widget.onSkipAll,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'TOUT PASSER',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.fast_forward,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // PR counter (top left)
                if (widget.totalPRs > 1)
                  Positioned(
                    top: 50,
                    left: 20,
                    child: Transform.scale(
                      scale: _textScale.value,
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'PR ${widget.currentPRIndex}/${widget.totalPRs}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Energy particles
                ..._buildParticles(),

                // Aura rings
                Center(
                  child: _buildAuraRings(),
                ),

                // Main content
                Center(
                  child: Transform.scale(
                    scale: _powerUpScale.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // PR Badge
                        _buildPRBadge(),

                        const SizedBox(height: 40),

                        // Exercise name and weight
                        Transform.scale(
                          scale: _textScale.value,
                          child: Opacity(
                            opacity: _textOpacity.value,
                            child: Column(
                              children: [
                                const Text(
                                  '🔥 NOUVEAU RECORD 🔥',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFFFFD700),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  widget.exerciseName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (widget.oldPR != null) ...[
                                      Text(
                                        '${widget.oldPR!.toStringAsFixed(1)} kg',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 24,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Color(0xFFFFD700),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    Text(
                                      '${widget.newPR.toStringAsFixed(1)} kg',
                                      style: TextStyle(
                                        color: _colorAnimation.value,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: _colorAnimation.value ?? AppColors.warning,
                                            blurRadius: 30,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.oldPR != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.success,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '+${(widget.newPR - widget.oldPR!).toStringAsFixed(1)} kg',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close button
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Transform.scale(
                    scale: _textScale.value,
                    child: Opacity(
                      opacity: _textOpacity.value,
                      child: Center(
                        child: GestureDetector(
                          onTap: widget.onComplete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _colorAnimation.value ?? AppColors.warning,
                                  AppColors.warning,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: (_colorAnimation.value ?? AppColors.warning)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Text(
                              'CONTINUER 💪',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPRBadge() {
    return AnimatedBuilder(
      animation: _auraController,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD700),
                const Color(0xFFFF8C00),
                Colors.transparent,
              ],
              stops: const [0.3, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: _auraOpacity.value),
                blurRadius: 40 * _auraScale.value,
                spreadRadius: 10 * _auraScale.value,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'PR',
              style: TextStyle(
                color: Colors.black,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuraRings() {
    return AnimatedBuilder(
      animation: _auraController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final scale = _auraScale.value + (index * 0.3);
            final opacity = (_auraOpacity.value - (index * 0.2)).clamp(0.0, 1.0);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: opacity),
                    width: 3 - index.toDouble(),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    return _particles.map((particle) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final progress = _particleController.value;
          final y = particle.y - (progress * 400 * particle.speed);
          final opacity = (1 - progress).clamp(0.0, 1.0);

          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + particle.x,
            top: MediaQuery.of(context).size.height / 2 + y,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: particle.size,
                height: particle.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _random.nextBool()
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFF8C00),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double angle;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
  });
}

// Helper function to check for PRs and show celebration
class PRChecker {
  static Future<Map<String, Map<String, double>>> checkForPRs({
    required Map<String, double> currentMaxWeights, // exerciseName -> maxWeight from this workout
    required Map<String, double> previousMaxWeights, // exerciseName -> previous best
  }) async {
    final newPRs = <String, Map<String, double>>{};

    for (final entry in currentMaxWeights.entries) {
      final exerciseName = entry.key;
      final currentMax = entry.value;
      final previousMax = previousMaxWeights[exerciseName];

      if (previousMax == null || currentMax > previousMax) {
        newPRs[exerciseName] = {
          'new': currentMax,
          'old': previousMax ?? 0,
        };
      }
    }

    return newPRs;
  }
}

/// Modal that sequences multiple PRCelebrationScreen instances without
/// popping between them. The modal stays open and advances to the next PR
/// when the user taps "Continuer". "Tout passer" closes the modal.
class PRSequenceModal extends StatefulWidget {
  final Map<String, Map<String, double>> prs;

  const PRSequenceModal({super.key, required this.prs});

  @override
  State<PRSequenceModal> createState() => _PRSequenceModalState();
}

class _PRSequenceModalState extends State<PRSequenceModal> {
  late final List<MapEntry<String, Map<String, double>>> _entries;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _entries = widget.prs.entries.toList();
  }

  void _onNext() {
    if (!mounted) return;
    if (_index < _entries.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onSkipAll() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entries[_index];

    return PRCelebrationScreen(
      exerciseName: entry.key,
      oldPR: entry.value['old']!,
      newPR: entry.value['new']!,
      currentPRIndex: _index + 1,
      totalPRs: _entries.length,
      onComplete: _onNext,
      onSkipAll: _entries.length > 1 ? _onSkipAll : null,
    );
  }
}
