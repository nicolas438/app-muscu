# Feature : Exercices Hors Séance

## 🎯 Objectif
Permettre aux utilisateurs d'ajouter des exercices qui ne font pas partie de la séance en cours, tout en gardant le tracking des PR (Personal Records).

## 💡 Cas d'usage
Un utilisateur fait une séance "Dos" mais veut noter qu'il a aussi fait du Bench Press ou du Deadlift en dehors de la séance planifiée. Ces exercices doivent être trackés pour les PR même s'ils ne font pas partie de la séance d'origine.

## ✨ Fonctionnalités

### 1. Bouton "Exercice hors séance"
- **Où** : Dans l'écran d'entraînement actif (`active_workout_screen.dart`), sous le bouton "Ajouter la série"
- **Style** : Bouton outlined avec icône `notebook_pen`
- **Action** : Ouvre un dialog pour ajouter un exercice hors séance

### 2. Dialog d'ajout
Le dialog permet de saisir :
- **Nom de l'exercice** : Texte libre (ex: "Bench Press", "Deadlift")
- **Poids** : En kg (accepte les décimales)
- **Reps** : Nombre entier

### 3. Distinction visuelle

#### Dans les tabs d'exercices
- Les exercices hors séance ont :
  - Une bordure bleue (`AppColors.accent`)
  - Une icône `notebook_pen` avant le numéro

#### Dans le panel de l'exercice
- Badge "HORS SÉANCE" en haut à gauche du nom
  - Fond bleu transparent
  - Bordure bleue
  - Icône `notebook_pen`

### 4. Intégration PR
Les exercices hors séance sont inclus dans :
- Le calcul des PR (Personal Records)
- Les statistiques du workout
- L'historique des exercices

## 🔧 Implémentation technique

### Modèle `ExerciseLog`
Ajout du champ `isOffSession` :
```dart
final bool isOffSession; // default: false
```

### Provider `ActiveWorkoutProvider`
Nouvelle méthode :
```dart
void addOffSessionExercise(String exerciseName, double weight, int reps)
```

### Persistance
- Le flag `isOffSession` est sauvegardé dans le JSON
- Compatibilité ascendante : les anciens logs ont `isOffSession: false` par défaut

## 🎨 Design

### Couleurs
- Badge/bordure : `AppColors.accent` (bleu électrique)
- Fond badge : `AppColors.accent` avec alpha 0.2
- Icône : `LucideIcons.notebook_pen`

### Spacing
- Badge : padding 8x4, margin-right 12
- Bouton : 12px de gap au-dessus

## 📝 Notes
- Un exercice hors séance est ajouté à la fin de la liste des exercices
- Il est traité comme un exercice normal pour les calculs de stats
- Le système de PR fonctionne exactement pareil pour ces exercices
- Le nom est en texte libre, permettant une flexibilité totale

## ✅ Feedback utilisateur
> "Franchement elle defonce  
> Faudrait juste ( jsp si tu peux faire ca ) créer une genre de note ou tu écris tout tes exercices en dehors des seances pour pouvoir mettre les PR sur des exo que tu as pas en seance  
> Genre le bench et deadlift on en fait rarement mais comme ca c'est note et on sait qu'on doir faire plus que ce qui est marque."

Cette feature répond exactement à ce besoin ! 🎉
