# AppNuno - Concept d'Application de Suivi d'Entraînement

## 📋 Vue d'ensemble

AppNuno est une application mobile de suivi des performances d'entraînement en musculation. Elle permet aux utilisateurs de créer des séances d'entraînement personnalisées, de logger leurs performances en temps réel, et d'analyser leur progression via des graphiques et comparaisons.

---

## 🎯 Fonctionnalités Principales

### 1. **Création de Séances**

L'utilisateur peut créer des séances d'entraînement personnalisées en définissant :
- **Nom de la séance** : ex. "Pecs-Épaules-Triceps"
- **Exercices** : ajouter plusieurs exercices à la séance
- **Ordre des exercices** : définir une séquence
- **Notes** : ajouter des notes spécifiques à la séance

**Exemple de séance :**
```
Séance 1 : Pecs-Épaules-Triceps
├─ Développé couché
├─ Écartés inclinés
├─ Développé militaire
├─ Élévations latérales
├─ Dips assistés
└─ Extension triceps à la corde
```

### 2. **Planification Hebdomadaire**

L'utilisateur peut :
- Créer **plusieurs séances par semaine** (ex. 4 séances : Pecs-Épaules-Triceps, Dos-Biceps, Jambes, etc.)
- Assigner chaque séance à des jours spécifiques
- Visualiser son planning hebdomadaire

**Exemple :**
```
Lundi : Pecs-Épaules-Triceps
Mardi : Repos
Mercredi : Dos-Biceps
Jeudi : Repos
Vendredi : Jambes
Samedi : Repos
Dimanche : Repos
```

### 3. **Enregistrement des Performances**

Lors de l'exécution d'une séance, l'utilisateur enregistre pour **chaque exercice** :
- **Poids utilisé** (en kg)
- **Nombre de répétitions** (reps)
- **Nombre de séries** (optionnel)
- **Date et heure** de la séance
- **Commentaires** (optionnel : sensations, difficulté, etc.)

**Structure des données enregistrées :**
```
Date: 2026-01-13
Séance: Pecs-Épaules-Triceps

Exercice 1: Développé couché
├─ Série 1: 80kg x 10 reps
├─ Série 2: 80kg x 9 reps
├─ Série 3: 75kg x 8 reps
└─ Notes: Bon jour

Exercice 2: Écartés inclinés
├─ Série 1: 30kg x 12 reps
├─ Série 2: 30kg x 11 reps
└─ Notes: Facile
```

### 4. **Sauvegarde Automatique**

- Chaque séance complétée est **sauvegardée automatiquement**
- Les données sont stockées localement (et/ou en cloud)
- Historique complet des performances conservé

---

## 📊 Analyse et Visualisation

### 5. **Graphiques Mensuels**

L'application génère des graphiques affichant :
- **Progression du poids** par exercice sur le mois
- **Evolution des répétitions** par exercice
- **Volume total** d'entraînement (poids x reps x séries)
- **Tendances** : amélioration, stagnation, régression

**Exemple de graphique :**
```
Développé couché - Janvier 2026
Poids maximum par semaine:
Semaine 1: 80kg
Semaine 2: 82kg
Semaine 3: 82kg
Semaine 4: 85kg
```

### 6. **Comparaisons par Exercice**

L'utilisateur peut :
- **Comparer les performances** d'un même exercice sur plusieurs mois
- **Analyser la progression** : amélioration, stagnation, nouvelle PR (Personal Record)
- **Visualiser les tendances** à long terme

**Exemple de comparaison :**
```
Développé couché - Comparaison 2025 vs 2026

Janvier 2025:
├─ Max: 75kg x 8 reps
├─ Volume: 1,200kg total
└─ Moyenne: 73kg par série

Janvier 2026:
├─ Max: 85kg x 6 reps
├─ Volume: 1,420kg total
└─ Moyenne: 78kg par série

Progression: +10kg sur le max (+13%)
```

---

## 🗂️ Architecture des Données

### Modèle de Données

```
Utilisateur
├─ Séances
│  ├─ Séance 1 (Pecs-Épaules-Triceps)
│  ├─ Séance 2 (Dos-Biceps)
│  └─ Séance 3 (Jambes)
│
├─ Planning Hebdomadaire
│  ├─ Lundi: Séance 1
│  ├─ Mercredi: Séance 2
│  └─ Vendredi: Séance 3
│
└─ Historique des Séances Complétées
   ├─ Entrée 1 (2026-01-13, Séance 1)
   │  ├─ Exercice 1: Données enregistrées
   │  ├─ Exercice 2: Données enregistrées
   │  └─ Exercice 3: Données enregistrées
   │
   └─ Entrée 2 (2026-01-15, Séance 2)
      └─ ...
```

---

## 🔄 Flux Utilisateur

### 1️⃣ **Onboarding - Création Initiale**
```
Bienvenue → Créer première séance → Ajouter exercices → Définir planning → Prêt !
```

### 2️⃣ **Entraînement - Exécution**
```
Voir planning du jour → Lancer la séance → Enregistrer poids/reps pour chaque exo → Fin de séance
```

### 3️⃣ **Analyse - Suivi**
```
Aller à Analytics → Sélectionner mois → Voir graphiques → Comparer avec mois précédent
```

---

## 💡 Cas d'Usage Détaillés

### Cas 1 : Utilisateur débutant
- Crée une première séance "Full Body" avec 5 exercices
- La lance 3 fois par semaine
- Enregistre ses performances
- Après 1 mois, voit sa progression sur chaque exercice

### Cas 2 : Utilisateur confirmé
- Crée 4 séances différentes (Push/Pull/Legs/Upper)
- Chacune personnalisée avec 6-8 exercices
- Lance une séance par jour
- Analyse mensuellement sa progression par muscle/exercice
- Ajuste ses charges en fonction des graphiques

---

## 🎨 Écrans Principaux

1. **Accueil** : Affiche la séance du jour, historique récent
2. **Créer/Gérer Séances** : Formulaire de création et édition
3. **Planning Hebdomadaire** : Vue calendrier avec les séances
4. **Entraînement Actif** : Interface pendant l'exécution (minuteur, saisie poids/reps)
5. **Analytics** : Graphiques et statistiques mensuelles
6. **Comparaisons** : Comparaisons par exercice inter-mois/mois
7. **Profil** : Paramètres utilisateur, unités, etc.

---

## 📱 Technologies Recommandées

- **Frontend** : Flutter (polyvalent, bonne performance)
- **Backend** : Firebase ou supabase (stockage + sync)
- **Base de données** : Firestore ou PostgreSQL
- **Graphiques** : fl_chart ou charts_flutter
- **Local Storage** : SQLite ou Hive

---

## ✨ Fonctionnalités Futures (Optionnelles)

- 📸 **Photos** : Avant/après photos de progression physique
- 👥 **Social** : Partager ses séances avec d'autres utilisateurs
- 🤖 **IA** : Recommandations d'exercices basées sur les performances
- 📲 **Notifications** : Rappels pour les jours d'entraînement
- 💪 **Défis** : Défi mensuels (x kg en développé couché, etc.)
- 🎯 **Objectifs** : Fixer des buts (atteindre 100kg au développé, etc.)
- 📋 **Export** : Exporter ses données en PDF/Excel

---

## 🎯 MVP (Minimum Viable Product)

Pour lancer une première version :

1. ✅ Créer séances avec exercices
2. ✅ Planifier séances sur la semaine
3. ✅ Enregistrer poids/reps lors d'une séance
4. ✅ Sauvegarder automatiquement
5. ✅ Voir graphique de progression mensuelle par exercice
6. ✅ Comparer 2 périodes

---

## 📝 Notes

- L'application prioritise la **simplicité d'utilisation** lors d'une séance
- Saisie rapide : poids + reps, sans friction
- Les analyses viennent après, mais doivent être **claires et motivantes**
- Persévérance = la clé du succès en musculation, l'app doit encourager cette constance
