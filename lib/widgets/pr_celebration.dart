import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Célébration plein écran des records battus en fin de séance.
///
/// Les records défilent un par un dans le même écran : « Continuer » passe
/// au suivant, puis ferme l'écran après le dernier. « Passer » ferme tout.
class PRSequenceModal extends StatefulWidget {
  final List<PersonalRecord> records;

  const PRSequenceModal({super.key, required this.records});

  @override
  State<PRSequenceModal> createState() => _PRSequenceModalState();
}

class _PRSequenceModalState extends State<PRSequenceModal> {
  int _index = 0;

  void _next() {
    if (_index < widget.records.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.records.length;

    return Scaffold(
      backgroundColor: AppColors.record,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.s, AppSpace.xl, AppSpace.xl),
          child: Column(
            children: [
              // Compteur et sortie rapide, seulement s'il y a plusieurs records.
              SizedBox(
                height: 48,
                child: total > 1
                    ? Row(
                        children: [
                          Text(
                            'Record ${_index + 1} sur $total',
                            style: AppText.label.copyWith(color: Colors.white70),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(foregroundColor: Colors.white),
                            child: const Text('Passer'),
                          ),
                        ],
                      )
                    : null,
              ),
              Expanded(
                // La clé force une nouvelle animation à chaque record.
                child: _RecordReveal(
                  key: ValueKey(_index),
                  record: widget.records[_index],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.background,
                  ),
                  child: Text(_index < total - 1 ? 'Record suivant' : 'Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Présentation animée d'un record : le chiffre « tombe » en place
/// comme un disque qu'on charge sur la barre.
class _RecordReveal extends StatefulWidget {
  final PersonalRecord record;

  const _RecordReveal({super.key, required this.record});

  @override
  State<_RecordReveal> createState() => _RecordRevealState();
}

class _RecordRevealState extends State<_RecordReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.6, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respecte le réglage « réduire les animations » du téléphone.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final set = record.recordSet;
    final isWeightRecord = record.kind == PersonalRecordKind.heaviestWeight;

    final headline = isWeightRecord
        ? formatKg(record.newValue)
        : '${formatWeight(set.weight)} × ${set.reps}';

    final detail = isWeightRecord
        ? 'Ancien record : ${formatKg(record.previousValue)}'
        : '1RM estimé : ${formatKg(record.newValue)}\n'
            'Ancien : ${formatKg(record.previousValue)}';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isWeightRecord ? 'Nouveau record de charge' : 'Nouveau record de force',
          style: AppText.heading.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: AppSpace.s),
        Text(
          record.exerciseName,
          style: AppText.title.copyWith(color: Colors.white, fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xl),
        FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                headline,
                style: AppText.figureXL.copyWith(color: Colors.white, fontSize: 88),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '+${formatKg(record.improvement)}',
            style: AppText.figureM.copyWith(color: AppColors.record),
          ),
        ),
        const SizedBox(height: AppSpace.l),
        Text(
          detail,
          style: AppText.body.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
