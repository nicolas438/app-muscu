# Direction graphique : « Fonte & disques »

L'interface emprunte son vocabulaire à la salle de musculation plutôt qu'aux
codes génériques des applications de sport.

## Couleurs

Un thème sombre couleur fonte, un texte couleur craie, et les couleurs officielles
des disques de compétition, éclaircies pour le fond sombre. Chaque couleur
d'accent a **un seul rôle** :

| Rôle | Couleur | Disque | Usage |
|---|---|---|---|
| Fond | `#101215` fonte | | Fond de tous les écrans |
| Surface | `#181B1F` | | Cartes, listes |
| Relief | `#22262B` | | Champs de saisie, boutons secondaires |
| Texte | `#F1F1EC` craie | | Textes, éléments sélectionnés |
| Action | `#3D6BFF` bleu | 20 kg | Boutons principaux, courbes |
| Record | `#FF4D3D` rouge | 25 kg | Records personnels uniquement |
| Repos et objectif | `#FFC233` jaune | 15 kg | Minuteur de repos, flammes |
| Validé | `#2FBF71` vert | 10 kg | Séries cochées, séances terminées |

Les séances choisissent leur couleur parmi les disques (rouge, bleu, jaune, vert,
gris, blanc). Elle colore la carte « Prévu aujourd'hui » de l'accueil et le grand
disque en filigrane de la carte de bilan.

## Typographie

- **Barlow** pour le texte : sobre, d'inspiration signalétique.
- **Barlow Condensed** très grasse pour les chiffres et les titres, comme les
  marquages des disques. Les chiffres ont une chasse fixe pour ne pas bouger
  quand une valeur change (chrono, compteurs).
- Libellés en minuscules (pas de capitales d'affichage) et vocabulaire simple.

## Principes

- **La séance avant tout** : tableau de séries lisible d'un coup d'œil, larges
  cases à cocher et minuteur de repos aux gros chiffres jaunes, utilisables mains
  pleines de magnésie.
- **Pas d'ombres ni de dégradés décoratifs** : la hiérarchie vient des trois
  niveaux de gris (fond, surface, relief). Un seul bloc coloré par écran au maximum.
- **Une seule animation mise en scène** : l'apparition du chiffre lors d'un
  record. Elle est désactivée si le téléphone demande de réduire les animations.
- **Les états vides guident** : ils expliquent quoi faire et proposent l'action.

Les jetons (couleurs, espacements, styles de texte) sont définis dans
`lib/theme/app_theme.dart`.
