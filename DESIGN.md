# Direction graphique : « Craie & disques »

L'interface emprunte son vocabulaire à la salle de musculation plutôt qu'aux
codes génériques des applications de sport.

## Couleurs

Un fond clair couleur magnésie, une encre couleur fer, et les quatre couleurs
officielles des disques de compétition. Chaque couleur d'accent a **un seul rôle** :

| Rôle | Couleur | Disque | Usage |
|---|---|---|---|
| Fond | `#F2F2EE` craie | | Fond de tous les écrans |
| Surface | `#FFFFFF` | | Panneaux, listes |
| Encre | `#1A1D21` fer | | Textes, carte de la séance du jour |
| Action | `#2453C8` bleu | 20 kg | Boutons principaux, courbes |
| Record | `#D63A2F` rouge | 25 kg | Records personnels uniquement |
| Objectif | `#F2B21B` jaune | 15 kg | Flammes et objectif hebdomadaire |
| Validé | `#23965A` vert | 10 kg | Séries et séances terminées |

Les séances choisissent leur couleur parmi les disques, affichée sous forme de
pastille percée comme un vrai disque (`PlateMarker`).

## Typographie

- **Barlow** pour le texte : sobre, d'inspiration signalétique.
- **Barlow Condensed** très grasse pour les chiffres et les titres, comme les
  marquages des disques. Les chiffres ont une chasse fixe pour ne pas bouger
  quand une valeur change (chrono, compteurs).
- Libellés en minuscules (pas de capitales d'affichage) et vocabulaire simple.

## Principes

- **Un seul élément spectaculaire** : la saisie de série, avec des chiffres de
  64 points et des boutons − / + de 60 points, utilisables mains pleines de magnésie.
  Le reste de l'interface reste discret.
- **Pas d'ombres ni de dégradés décoratifs** : la hiérarchie vient du contraste
  craie / blanc / encre. Un seul bloc sombre par écran au maximum.
- **Une seule animation mise en scène** : l'apparition du chiffre lors d'un
  record. Elle est désactivée si le téléphone demande de réduire les animations.
- **Les états vides guident** : ils expliquent quoi faire et proposent l'action.

Les jetons (couleurs, espacements, styles de texte) sont définis dans
`lib/theme/app_theme.dart`.
