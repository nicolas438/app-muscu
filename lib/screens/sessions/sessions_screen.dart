import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/widgets.dart';
import '../workout/start_workout.dart';

/// Groupes musculaires proposés pour classer les exercices.
const List<String> kMuscleGroups = [
  'Pectoraux',
  'Dos',
  'Épaules',
  'Jambes',
  'Bras',
  'Abdos',
  'Cardio',
];

/// Onglet « Séances » : séances d'entraînement et bibliothèque d'exercices.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    // Met à jour le libellé du bouton d'ajout selon l'onglet affiché.
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSessionsTab = _tabController.index == 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpace.page, AppSpace.l, AppSpace.page, AppSpace.l),
              child: Text('Séances', style: AppText.display),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              child: _SegmentedTabs(controller: _tabController),
            ),
            const SizedBox(height: AppSpace.s),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_SessionsTab(), _ExercisesTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => onSessionsTab ? openSessionEditor(context) : showExerciseEditor(context),
        backgroundColor: AppColors.inverse,
        foregroundColor: AppColors.onInverse,
        elevation: 2,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(onSessionsTab ? 'Nouvelle séance' : 'Nouvel exercice'),
      ),
    );
  }
}

/// Sélecteur à deux segments, au style de l'application.
class _SegmentedTabs extends StatelessWidget {
  final TabController controller;

  const _SegmentedTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.inverse,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.onInverse,
        unselectedLabelColor: AppColors.textSoft,
        labelStyle: AppText.label.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppText.label,
        splashBorderRadius: BorderRadius.circular(AppRadius.s),
        tabs: const [Tab(text: 'Mes séances'), Tab(text: 'Exercices')],
      ),
    );
  }
}

// =============================================================================
// SÉANCES
// =============================================================================

/// Ouvre l'éditeur de séance (création si [session] est nul).
void openSessionEditor(BuildContext context, [WorkoutSession? session]) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EditSessionScreen(session: session),
      fullscreenDialog: true,
    ),
  );
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    if (provider.sessions.isEmpty) {
      return EmptyState(
        icon: LucideIcons.dumbbell,
        title: 'Aucune séance',
        message: 'Une séance regroupe les exercices que tu enchaînes, par exemple « Pecs-Épaules-Triceps ».',
        actionLabel: 'Créer une séance',
        onAction: () => openSessionEditor(context),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.m, AppSpace.page, 96),
      itemCount: provider.sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.m),
      itemBuilder: (context, index) => _SessionCard(session: provider.sessions[index]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkoutProvider>();
    final names = session.exerciseRefs
        .map((ref) => provider.getGlobalExerciseById(ref.exerciseId)?.name)
        .whereType<String>()
        .toList();

    final preview = names.length <= 3
        ? names.join(', ')
        : '${names.take(3).join(', ')} et ${names.length - 3} autre${names.length - 3 > 1 ? 's' : ''}';

    return Panel(
      onTap: () => openSessionEditor(context, session),
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.l, AppSpace.m, AppSpace.l),
      child: Row(
        children: [
          PlateMarker(color: AppColors.sessionColor(session.color), size: 22),
          const SizedBox(width: AppSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.name, style: AppText.title.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(plural(names.length, 'exercice'), style: AppText.label),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    preview,
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.s),
          IconButton.filled(
            onPressed: () => startWorkout(context, session),
            tooltip: 'Lancer la séance',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(LucideIcons.play, size: 20),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BIBLIOTHÈQUE D'EXERCICES
// =============================================================================

class _ExercisesTab extends StatefulWidget {
  const _ExercisesTab();

  @override
  State<_ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<_ExercisesTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    if (provider.globalExercises.isEmpty) {
      return EmptyState(
        icon: LucideIcons.list,
        title: 'Aucun exercice',
        message: 'Ajoute les exercices que tu pratiques pour composer tes séances.',
        actionLabel: 'Ajouter un exercice',
        onAction: () => showExerciseEditor(context),
      );
    }

    final records = provider.getAllPreviousPRs();
    final exercises = provider.searchGlobalExercises(_query);

    // Regroupement par groupe musculaire, dans l'ordre de [kMuscleGroups],
    // les exercices sans catégorie en dernier.
    final groups = <String, List<GlobalExercise>>{};
    for (final exercise in exercises) {
      groups.putIfAbsent(exercise.category ?? '', () => []).add(exercise);
    }
    final orderedKeys = [
      ...kMuscleGroups.where(groups.containsKey),
      ...groups.keys.where((k) => k.isNotEmpty && !kMuscleGroups.contains(k)),
      if (groups.containsKey('')) '',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.m, AppSpace.page, 96),
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            hintText: 'Rechercher un exercice',
            prefixIcon: const Icon(LucideIcons.search, size: 20, color: AppColors.textFaint),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    tooltip: 'Effacer la recherche',
                    onPressed: () => setState(() {
                      _query = '';
                      _searchController.clear();
                    }),
                  ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        if (exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xl),
            child: Text(
              'Aucun exercice ne correspond à « $_query ».',
              style: AppText.body.copyWith(color: AppColors.textSoft),
              textAlign: TextAlign.center,
            ),
          ),
        for (final key in orderedKeys) ...[
          SectionTitle(key.isEmpty ? 'Sans catégorie' : key),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < groups[key]!.length; i++) ...[
                  if (i > 0) const Divider(indent: AppSpace.l, endIndent: AppSpace.l),
                  _ExerciseRow(
                    exercise: groups[key]![i],
                    record: records[groups[key]![i].name],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
        ],
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final GlobalExercise exercise;
  final double? record;

  const _ExerciseRow({required this.exercise, required this.record});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showExerciseEditor(context, exercise),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.m + 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: AppText.heading),
                  if (exercise.isUnilateral) ...[
                    const SizedBox(height: 2),
                    const Text('Unilatéral, gauche et droite', style: AppText.caption),
                  ],
                  if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      exercise.notes!,
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.m),
            if (record != null && record! > 0) ...[
              const Icon(LucideIcons.trophy, size: 14, color: AppColors.record),
              const SizedBox(width: AppSpace.xs),
              Text(formatKg(record!), style: AppText.figureM.copyWith(fontSize: 18)),
            ] else
              const Text('Jamais réalisé', style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

/// Fenêtre de création ou de modification d'un exercice de la bibliothèque.
///
/// Renvoie l'exercice créé (utile pour l'ajouter directement à une séance).
Future<GlobalExercise?> showExerciseEditor(
  BuildContext context, [
  GlobalExercise? exercise,
  String? initialName,
]) async {
  final provider = context.read<WorkoutProvider>();
  final result = await showModalBottomSheet<_ExerciseEditorResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ExerciseEditorSheet(exercise: exercise, initialName: initialName),
  );
  if (result == null) return null;

  if (result.delete && exercise != null) {
    await provider.deleteGlobalExercise(exercise.id);
    return null;
  }

  if (exercise == null) {
    final created = GlobalExercise(
      id: StorageService().generateId(),
      name: result.name,
      notes: result.notes,
      category: result.category,
      isUnilateral: result.isUnilateral,
    );
    await provider.addGlobalExercise(created);
    return created;
  }

  // copyWith ne permet pas de remettre un champ à null : on reconstruit.
  final updated = GlobalExercise(
    id: exercise.id,
    name: result.name,
    notes: result.notes,
    category: result.category,
    isUnilateral: result.isUnilateral,
    createdAt: exercise.createdAt,
  );
  await provider.updateGlobalExercise(updated);
  return updated;
}

class _ExerciseEditorResult {
  final String name;
  final String? notes;
  final String? category;
  final bool isUnilateral;
  final bool delete;

  const _ExerciseEditorResult({
    this.name = '',
    this.notes,
    this.category,
    this.isUnilateral = false,
    this.delete = false,
  });
}

class _ExerciseEditorSheet extends StatefulWidget {
  final GlobalExercise? exercise;
  final String? initialName;

  const _ExerciseEditorSheet({this.exercise, this.initialName});

  @override
  State<_ExerciseEditorSheet> createState() => _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends State<_ExerciseEditorSheet> {
  late final _nameController = TextEditingController(
    text: widget.exercise?.name ?? widget.initialName ?? '',
  );
  late final _notesController = TextEditingController(text: widget.exercise?.notes ?? '');
  late String? _category = widget.exercise?.category;
  late bool _isUnilateral = widget.exercise?.isUnilateral ?? false;

  bool get _isEditing => widget.exercise != null;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final notes = _notesController.text.trim();
    Navigator.pop(
      context,
      _ExerciseEditorResult(
        name: name,
        notes: notes.isEmpty ? null : notes,
        category: _category,
        isUnilateral: _isUnilateral,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${widget.exercise!.name} » ?'),
        content: const Text(
          'Il sera retiré de toutes tes séances. Ton historique et tes statistiques sont conservés.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, const _ExerciseEditorResult(delete: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Remonte la feuille au-dessus du clavier.
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, AppSpace.xl + keyboard),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEditing ? 'Modifier l\'exercice' : 'Nouvel exercice', style: AppText.title),
            const SizedBox(height: AppSpace.l),
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(labelText: 'Nom', hintText: 'Ex. : Développé couché'),
            ),
            const SizedBox(height: AppSpace.l),
            const Text('Groupe musculaire', style: AppText.label),
            const SizedBox(height: AppSpace.s),
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                for (final group in kMuscleGroups)
                  ChoiceChip(
                    label: Text(group),
                    selected: _category == group,
                    showCheckmark: false,
                    selectedColor: AppColors.inverse,
                    backgroundColor: AppColors.surfaceRaised,
                    side: BorderSide.none,
                    labelStyle: AppText.label.copyWith(
                      color: _category == group ? AppColors.onInverse : AppColors.text,
                    ),
                    onSelected: (selected) => setState(() => _category = selected ? group : null),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.s),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isUnilateral,
              onChanged: (value) => setState(() => _isUnilateral = value),
              activeColor: AppColors.primary,
              title: const Text('Unilatéral', style: AppText.heading),
              subtitle: const Text(
                'Un côté à la fois (curl haltère, fente…) : répétitions saisies pour la gauche et la droite.',
                style: AppText.caption,
              ),
            ),
            const SizedBox(height: AppSpace.s),
            TextField(
              controller: _notesController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (facultatif)',
                hintText: 'Réglages de la machine, placement…',
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Enregistrer' : 'Ajouter l\'exercice'),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: AppSpace.s),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _confirmDelete,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Supprimer l\'exercice'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ÉDITEUR DE SÉANCE
// =============================================================================

/// Création ou modification d'une séance : nom, couleur, exercices et ordre.
class EditSessionScreen extends StatefulWidget {
  final WorkoutSession? session;

  const EditSessionScreen({super.key, this.session});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.session?.name ?? '');
  late final _notesController = TextEditingController(text: widget.session?.notes ?? '');
  late final List<SessionExerciseRef> _exerciseRefs = List.of(widget.session?.exerciseRefs ?? []);
  late int _colorIndex = (int.tryParse(widget.session?.color ?? '') ?? 1).abs() %
      AppColors.sessionColors.length;

  bool get _isEditing => widget.session != null;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _renumber() {
    for (var i = 0; i < _exerciseRefs.length; i++) {
      _exerciseRefs[i] = _exerciseRefs[i].copyWith(order: i);
    }
  }

  /// Ouvre le sélecteur : les exercices décochés sont retirés, les nouveaux
  /// ajoutés à la fin, et l'ordre des exercices conservés est préservé.
  Future<void> _pickExercises() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExercisePickerSheet(
        initialSelection: _exerciseRefs.map((r) => r.exerciseId).toList(),
      ),
    );
    if (selected == null) return;

    setState(() {
      _exerciseRefs.removeWhere((ref) => !selected.contains(ref.exerciseId));
      for (final id in selected) {
        if (!_exerciseRefs.any((ref) => ref.exerciseId == id)) {
          _exerciseRefs.add(SessionExerciseRef(exerciseId: id));
        }
      }
      _renumber();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<WorkoutProvider>();
    final notes = _notesController.text.trim();
    final session = WorkoutSession(
      id: widget.session?.id ?? StorageService().generateId(),
      name: _nameController.text.trim(),
      exerciseRefs: _exerciseRefs,
      notes: notes.isEmpty ? null : notes,
      color: _colorIndex.toString(),
    );

    if (_isEditing) {
      provider.updateSession(session);
    } else {
      provider.addSession(session);
    }
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer « ${widget.session!.name} » ?'),
        content: const Text('Elle sera aussi retirée du planning. Ton historique est conservé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<WorkoutProvider>().deleteSession(widget.session!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la séance' : 'Nouvelle séance'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          tooltip: 'Fermer sans enregistrer',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.s),
            child: TextButton(onPressed: _save, child: const Text('Enregistrer')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.s, AppSpace.page, AppSpace.xxl),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.title,
              decoration: const InputDecoration(
                labelText: 'Nom de la séance',
                hintText: 'Ex. : Pecs-Épaules-Triceps',
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Donne un nom à ta séance' : null,
            ),
            const SizedBox(height: AppSpace.xl),

            const Text('Couleur', style: AppText.label),
            const SizedBox(height: AppSpace.s),
            Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.s,
              children: [
                for (var i = 0; i < AppColors.sessionColors.length; i++)
                  _ColorOption(
                    color: AppColors.sessionColors[i],
                    selected: _colorIndex == i,
                    onTap: () => setState(() => _colorIndex = i),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),

            SectionTitle(
              'Exercices',
              trailing: Text(plural(_exerciseRefs.length, 'exercice'), style: AppText.label),
            ),
            if (_exerciseRefs.isEmpty)
              Panel(
                color: AppColors.surfaceRaised,
                child: Text(
                  'Aucun exercice pour l\'instant. Ajoute ceux que tu enchaînes, dans l\'ordre que tu préfères.',
                  style: AppText.body.copyWith(color: AppColors.textSoft),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _exerciseRefs.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final ref = _exerciseRefs.removeAt(oldIndex);
                    _exerciseRefs.insert(newIndex, ref);
                    _renumber();
                  });
                },
                itemBuilder: (context, index) {
                  final ref = _exerciseRefs[index];
                  final exercise = provider.getGlobalExerciseById(ref.exerciseId);
                  return _ExerciseRefRow(
                    key: ValueKey(ref.exerciseId),
                    index: index,
                    name: exercise?.name ?? 'Exercice supprimé',
                    onRemove: () => setState(() {
                      _exerciseRefs.removeAt(index);
                      _renumber();
                    }),
                  );
                },
              ),
            const SizedBox(height: AppSpace.m),
            OutlinedButton.icon(
              onPressed: _pickExercises,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Ajouter des exercices'),
            ),
            const SizedBox(height: AppSpace.xl),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (facultatif)',
                hintText: 'Échauffement, temps de repos…',
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: AppSpace.xxl),
              TextButton(
                onPressed: _confirmDelete,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Supprimer la séance'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? AppColors.text : Colors.transparent, width: 2),
        ),
        child: PlateMarker(color: color, size: 34, holeColor: AppColors.background),
      ),
    );
  }
}

class _ExerciseRefRow extends StatelessWidget {
  final int index;
  final String name;
  final VoidCallback onRemove;

  const _ExerciseRefRow({
    super.key,
    required this.index,
    required this.name,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.xs, AppSpace.xs, AppSpace.xs),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('${index + 1}', style: AppText.figureM.copyWith(color: AppColors.textFaint)),
            ),
            const SizedBox(width: AppSpace.s),
            Expanded(child: Text(name, style: AppText.heading)),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Retirer de la séance',
              icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textSoft),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(AppSpace.m),
                child: Icon(LucideIcons.grip_vertical, size: 20, color: AppColors.textFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sélection multiple d'exercices dans la bibliothèque, avec recherche et
/// création à la volée d'un exercice manquant.
class _ExercisePickerSheet extends StatefulWidget {
  final List<String> initialSelection;

  const _ExercisePickerSheet({required this.initialSelection});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  late final List<String> _selected = List.of(widget.initialSelection);
  String _query = '';

  Future<void> _createExercise() async {
    final created = await showExerciseEditor(context, null, _query);
    if (created != null && mounted) {
      setState(() => _selected.add(created.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final exercises = provider.searchGlobalExercises(_query);
    final height = MediaQuery.of(context).size.height * 0.85;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter des exercices', style: AppText.title),
                const SizedBox(height: AppSpace.l),
                TextField(
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher',
                    prefixIcon: Icon(LucideIcons.search, size: 20, color: AppColors.textFaint),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
              children: [
                for (final exercise in exercises)
                  CheckboxListTile(
                    value: _selected.contains(exercise.id),
                    title: Text(exercise.name, style: AppText.heading),
                    subtitle: exercise.category == null
                        ? null
                        : Text(exercise.category!, style: AppText.caption),
                    controlAffinity: ListTileControlAffinity.trailing,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.s)),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(exercise.id);
                      } else {
                        _selected.remove(exercise.id);
                      }
                    }),
                  ),
                // Proposer de créer l'exercice s'il n'existe pas encore.
                ListTile(
                  leading: const Icon(LucideIcons.plus, color: AppColors.primary),
                  title: Text(
                    _query.isEmpty ? 'Créer un exercice' : 'Créer « $_query »',
                    style: AppText.heading.copyWith(color: AppColors.primary),
                  ),
                  onTap: _createExercise,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.s, AppSpace.xl, AppSpace.l),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text('Valider (${_selected.length})'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
