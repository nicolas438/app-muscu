import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Bilan d'une séance, présenté comme une carte à partager en image.
class WorkoutSummaryScreen extends StatefulWidget {
  final CompletedWorkout workout;
  final List<PersonalRecord> records;

  const WorkoutSummaryScreen({super.key, required this.workout, required this.records});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  /// Repère de la carte, pour la convertir en image.
  final _cardKey = GlobalKey();
  bool _isSharing = false;

  /// Capture la carte en PNG haute définition et ouvre le partage du téléphone.
  Future<void> _share() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Image vide');

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(data.buffer.asUint8List(), mimeType: 'image/png')],
          fileNameOverrides: const ['bilan-seance.png'],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le partage n\'a pas pu s\'ouvrir. Réessaie dans un instant.')),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<WorkoutProvider>().getSessionById(widget.workout.sessionId);
    final accent = session == null ? AppColors.primary : AppColors.sessionColor(session.color);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilan de la séance'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          tooltip: 'Fermer',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s, AppSpace.page, AppSpace.l),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: SummaryCard(workout: widget.workout, records: widget.records, accent: accent),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.l),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSharing ? null : _share,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Partager'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de bilan : séance, chiffres clés, records et meilleure série de
/// chaque exercice. Conçue pour être lisible une fois partagée en image.
class SummaryCard extends StatelessWidget {
  final CompletedWorkout workout;
  final List<PersonalRecord> records;
  final Color accent;

  const SummaryCard({
    super.key,
    required this.workout,
    required this.records,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final date = capitalize(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(workout.date));
    final logs = workout.exerciseLogs.where((log) => log.sets.isNotEmpty).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.l + 4),
      child: Container(
        color: AppColors.surface,
        child: Stack(
          children: [
            // Grand disque en filigrane, dans la couleur de la séance.
            Positioned(
              top: -70,
              right: -70,
              child: CustomPaint(
                size: const Size(240, 240),
                painter: _PlatePainter(color: accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: AppText.label),
                  const SizedBox(height: AppSpace.s),
                  Text(workout.sessionName, style: AppText.display.copyWith(fontSize: 44)),
                  const SizedBox(height: AppSpace.m),
                  Container(width: 48, height: 4, color: accent),
                  const SizedBox(height: AppSpace.xl),

                  // Chiffres clés.
                  Row(
                    children: [
                      Expanded(child: _Figure(value: formatDuration(workout.duration), label: 'durée')),
                      Expanded(child: _Figure(value: formatVolume(workout.totalVolume), label: 'soulevés')),
                      Expanded(
                        child: _Figure(
                          value: '${workout.totalSets}',
                          label: workout.totalSets > 1 ? 'séries' : 'série',
                        ),
                      ),
                    ],
                  ),

                  if (records.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpace.l),
                      decoration: BoxDecoration(
                        color: AppColors.record.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.m),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.trophy, size: 16, color: AppColors.record),
                              const SizedBox(width: AppSpace.s),
                              Text(
                                records.length > 1 ? '${records.length} records battus' : 'Record battu',
                                style: AppText.heading.copyWith(color: AppColors.record),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.s),
                          for (final record in records)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpace.xs),
                              child: Row(
                                children: [
                                  Expanded(child: Text(record.exerciseName, style: AppText.body)),
                                  Text(
                                    record.kind == PersonalRecordKind.heaviestWeight
                                        ? formatKg(record.newValue)
                                        : '${formatWeight(record.recordSet.weight)} × ${record.recordSet.reps}',
                                    style: AppText.figureM.copyWith(fontSize: 19),
                                  ),
                                  const SizedBox(width: AppSpace.s),
                                  Text(
                                    '+${formatKg(record.improvement)}',
                                    style: AppText.label.copyWith(color: AppColors.record),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpace.xl),
                  const Text('Meilleures séries', style: AppText.label),
                  const SizedBox(height: AppSpace.s),
                  for (final log in logs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.s - 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.exerciseName,
                              style: AppText.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${formatWeight(log.bestSet!.weight)} kg × ${log.bestSet!.reps}',
                            style: AppText.figureM.copyWith(fontSize: 19),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpace.xl),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AppSpace.s),
                      Text('AppNuno', style: AppText.caption.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String value;
  final String label;

  const _Figure({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: AppText.figureL),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption),
      ],
    );
  }
}

/// Silhouette d'un disque de musculation : disque plein, rebord, gorge et
/// trou central, en transparence.
class _PlatePainter extends CustomPainter {
  final Color color;

  const _PlatePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: 0.16));

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = color.withValues(alpha: 0.28);
    canvas.drawCircle(center, radius * 0.88, ring..strokeWidth = 3);
    canvas.drawCircle(center, radius * 0.42, ring..strokeWidth = 6);

    canvas.drawCircle(center, radius * 0.16, Paint()..color = AppColors.surface);
  }

  @override
  bool shouldRepaint(covariant _PlatePainter oldDelegate) => oldDelegate.color != color;
}
