import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/widgets.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Séances'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.warning,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppColors.warning,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Séances'),
            Tab(text: 'Exercices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SessionsTab(),
          _ExercisesTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          if (_tabController.index == 0) {
            return FloatingActionButton(
              onPressed: () => _showCreateSessionDialog(context),
              child: const Icon(LucideIcons.plus),
            );
          } else {
            return FloatingActionButton(
              onPressed: () => _showCreateExerciseDialog(context),
              child: const Icon(LucideIcons.plus),
            );
          }
        },
      ),
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EditSessionScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showCreateExerciseDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvel exercice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Bench Press',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Instructions, conseils...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final provider = context.read<WorkoutProvider>();
      final exercise = GlobalExercise(
        id: StorageService().generateId(),
        name: nameController.text.trim(),
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      await provider.addGlobalExercise(exercise);
    }
  }

  void _showEditExerciseDialog(BuildContext context, GlobalExercise exercise) async {
    final nameController = TextEditingController(text: exercise.name);
    final notesController = TextEditingController(text: exercise.notes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier l\'exercice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nom',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final provider = context.read<WorkoutProvider>();
      final updated = exercise.copyWith(
        name: nameController.text.trim(),
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      );
      await provider.updateGlobalExercise(updated);
    }
  }

  void _confirmDeleteExercise(BuildContext context, GlobalExercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'exercice ?'),
        content: Text('Es-tu sûr de vouloir supprimer "${exercise.name}" ?\n\nIl sera retiré de toutes les séances.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<WorkoutProvider>().deleteGlobalExercise(exercise.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        if (provider.sessions.isEmpty) {
          return EmptyState(
            icon: LucideIcons.dumbbell,
            title: 'Aucune séance',
            subtitle: 'Crée ta première séance d\'entraînement',
            buttonLabel: 'Créer une séance',
            onButtonPressed: () => _showCreateSessionDialog(context),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          itemCount: provider.sessions.length,
          itemBuilder: (context, index) {
            final session = provider.sessions[index];
            return _SessionCard(session: session);
          },
        );
      },
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EditSessionScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _ExercisesTab extends StatefulWidget {
  const _ExercisesTab();

  @override
  State<_ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<_ExercisesTab> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        var filteredExercises = provider.globalExercises;
        
        if (_searchQuery.isNotEmpty) {
          filteredExercises = filteredExercises.where((ex) {
            return ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (provider.globalExercises.isEmpty) {
          return EmptyState(
            icon: LucideIcons.dumbbell,
            title: 'Aucun exercice',
            subtitle: 'Crée tes exercices pour les utiliser dans tes séances',
            buttonLabel: 'Créer un exercice',
            onButtonPressed: () {
              final state = context.findAncestorStateOfType<_SessionsScreenState>();
              state?._showCreateExerciseDialog(context);
            },
          );
        }

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Rechercher un exercice...',
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.textTertiary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, color: AppColors.textTertiary),
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          }),
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            // Exercise list
            Expanded(
              child: filteredExercises.isEmpty
                  ? EmptyState(
                      icon: LucideIcons.search,
                      title: 'Aucun résultat',
                      subtitle: 'Essaie une autre recherche',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];
                        final state = context.findAncestorStateOfType<_SessionsScreenState>();
                        return _GlobalExerciseCard(
                          exercise: exercise,
                          onEdit: () => state?._showEditExerciseDialog(context, exercise),
                          onDelete: () => state?._confirmDeleteExercise(context, exercise),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _GlobalExerciseCard extends StatelessWidget {
  final GlobalExercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GlobalExerciseCard({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        // Get PR for this exercise
        final allPRs = provider.getAllPreviousPRs();
        final pr = allPRs[exercise.name];
        
        return GradientCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.dumbbell,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (pr != null && pr > 0) ...[
                      Row(
                        children: [
                          const Icon(LucideIcons.trophy, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            'PR: ${pr.toStringAsFixed(pr.truncateToDouble() == pr ? 0 : 1)}kg',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ] else if (exercise.notes != null) ...[
                      Text(
                        exercise.notes!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      const Text(
                        'Pas encore effectué',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 18),
                color: AppColors.textSecondary,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash_2, size: 18),
                color: AppColors.error,
                onPressed: onDelete,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExerciseStats {
  final String name;
  final Set<String> sessions;
  ExerciseSet? bestSet;
  DateTime lastPerformed;
  int totalSets;

  ExerciseStats({
    required this.name,
    required this.sessions,
    this.bestSet,
    required this.lastPerformed,
    required this.totalSets,
  });
}

class _SessionCard extends StatelessWidget {
  final WorkoutSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final colorIndex = session.color != null
        ? int.tryParse(session.color!) ?? 0
        : session.name.hashCode % AppColors.sessionColors.length;
    final sessionColor = AppColors.sessionColors[colorIndex.abs() % AppColors.sessionColors.length];

    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        // Get exercise names from refs
        final exerciseNames = session.exerciseRefs
            .map((ref) => provider.getGlobalExerciseById(ref.exerciseId)?.name)
            .whereType<String>()
            .toList();

        return GradientCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _editSession(context),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: sessionColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exerciseNames.length} exercice${exerciseNames.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (exerciseNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: exerciseNames.take(3).map((name) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash_2, color: AppColors.error, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditSessionScreen(session: session),
        fullscreenDialog: true,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la séance ?'),
        content: Text('Es-tu sûr de vouloir supprimer "${session.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<WorkoutProvider>().deleteSession(session.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class EditSessionScreen extends StatefulWidget {
  final WorkoutSession? session;

  const EditSessionScreen({super.key, this.session});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _storage = StorageService();

  List<SessionExerciseRef> _exerciseRefs = [];
  int _selectedColorIndex = 0;

  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _nameController.text = widget.session!.name;
      _notesController.text = widget.session!.notes ?? '';
      _exerciseRefs = List.from(widget.session!.exerciseRefs);
      _selectedColorIndex = int.tryParse(widget.session!.color ?? '0') ?? 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la séance' : 'Nouvelle séance'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveSession,
            child: const Text(
              'Sauvegarder',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Session Name
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nom de la séance',
                hintText: 'Ex: Pecs-Épaules-Triceps',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Color Selection
            const Text(
              'Couleur',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(AppColors.sessionColors.length, (index) {
                  final color = AppColors.sessionColors[index];
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Ajouter des notes...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Exercises Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exercices',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showExercisePicker,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text(
                    'Ajouter',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Exercises List
            Consumer<WorkoutProvider>(
              builder: (context, provider, _) {
                if (_exerciseRefs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.surfaceHighlight,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(LucideIcons.list, color: AppColors.textTertiary, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Aucun exercice',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exerciseRefs.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final ref = _exerciseRefs.removeAt(oldIndex);
                      _exerciseRefs.insert(newIndex, ref);
                      _updateExerciseOrders();
                    });
                  },
                  itemBuilder: (context, index) {
                    final ref = _exerciseRefs[index];
                    final exercise = provider.getGlobalExerciseById(ref.exerciseId);
                    if (exercise == null) return const SizedBox.shrink();

                    return _ExerciseRefItem(
                      key: ValueKey(ref.exerciseId),
                      exerciseName: exercise.name,
                      index: index,
                      onDelete: () => _deleteExercise(index),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateExerciseOrders() {
    for (var i = 0; i < _exerciseRefs.length; i++) {
      _exerciseRefs[i] = _exerciseRefs[i].copyWith(order: i);
    }
  }

  Future<void> _showExercisePicker() async {
    final provider = context.read<WorkoutProvider>();
    
    // If no global exercises exist, offer to create one
    if (provider.globalExercises.isEmpty) {
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aucun exercice'),
          content: const Text('Tu dois d\'abord créer des exercices dans l\'onglet "Exercices".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _ExercisePickerDialog(
        availableExercises: provider.globalExercises,
        selectedExerciseIds: _exerciseRefs.map((r) => r.exerciseId).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        // Add new exercises
        for (var exerciseId in selected) {
          if (!_exerciseRefs.any((r) => r.exerciseId == exerciseId)) {
            _exerciseRefs.add(SessionExerciseRef(
              exerciseId: exerciseId,
              order: _exerciseRefs.length,
            ));
          }
        }
      });
    }
  }

  void _deleteExercise(int index) {
    setState(() {
      _exerciseRefs.removeAt(index);
      _updateExerciseOrders();
    });
  }

  void _saveSession() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<WorkoutProvider>();
    final session = WorkoutSession(
      id: widget.session?.id ?? _storage.generateId(),
      name: _nameController.text.trim(),
      exerciseRefs: _exerciseRefs,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      color: _selectedColorIndex.toString(),
    );

    if (_isEditing) {
      provider.updateSession(session);
    } else {
      provider.addSession(session);
    }

    Navigator.pop(context);
  }
}

// New widget for exercise reference item
class _ExerciseRefItem extends StatelessWidget {
  final String exerciseName;
  final int index;
  final VoidCallback onDelete;

  const _ExerciseRefItem({
    super.key,
    required this.exerciseName,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          exerciseName,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.trash_2, size: 18),
              color: AppColors.error,
              onPressed: onDelete,
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                LucideIcons.grip_vertical,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Exercise Picker Dialog
class _ExercisePickerDialog extends StatefulWidget {
  final List<GlobalExercise> availableExercises;
  final List<String> selectedExerciseIds;

  const _ExercisePickerDialog({
    required this.availableExercises,
    required this.selectedExerciseIds,
  });

  @override
  State<_ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<_ExercisePickerDialog> {
  late List<String> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedExerciseIds);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.availableExercises.where((ex) {
      if (_searchQuery.isEmpty) return true;
      return ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Sélectionner des exercices'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(LucideIcons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final exercise = filtered[index];
                  final isSelected = _selected.contains(exercise.id);
                  return CheckboxListTile(
                    title: Text(
                      exercise.name,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    value: isSelected,
                    activeColor: AppColors.warning,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(exercise.id);
                        } else {
                          _selected.remove(exercise.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

