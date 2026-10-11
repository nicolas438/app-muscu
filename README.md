# AppNuno

Carnet d'entraînement de musculation pour Android et iOS, développé avec Flutter.
Toutes les données restent sur le téléphone (stockage local Hive) : l'application
fonctionne sans connexion, y compris à la salle.

## Fonctionnalités

- **Séances** : bibliothèque d'exercices classés par groupe musculaire, et séances
  composées à partir de cette bibliothèque (ordre modifiable, couleur au choix).
- **Planning** : une séance ou du repos pour chaque jour de la semaine ; la séance
  du jour s'affiche sur l'accueil. N'importe quelle séance peut être lancée à tout moment.
- **Entraînement** : saisie charge × répétitions avec de larges boutons − / +,
  rappel de la meilleure série de la dernière séance, exercices hors séance.
  La séance en cours est sauvegardée en continu : elle peut être mise en pause et
  reprise, même après la fermeture de l'application.
- **Records** : détectés en fin de séance sur la charge maximale et sur le 1RM
  estimé (formule d'Epley), pour valoriser aussi les répétitions gagnées.
- **Objectif hebdomadaire** : nombre de séances visé par semaine ; chaque semaine
  tenue prolonge la série (flammes). Les semaines suivent la norme ISO 8601.
- **Statistiques** : volume par semaine, par mois ou au total, courbe de progression
  par exercice (charge ou 1RM estimé) et comparaison avec la période précédente.

## Démarrer

```bash
flutter pub get
flutter run
```

Lancer les tests :

```bash
flutter test
```

Générer un APK à installer directement sur un téléphone Android :

```bash
flutter build apk --release
# Fichier produit : build/app/outputs/flutter-apk/app-release.apk
```

## Organisation du code

```
lib/
├── main.dart           Initialisation (stockage, langue, thème)
├── models/             Données : séances, exercices, séries, records, objectif
├── providers/          État de l'application (Provider)
├── services/           Lecture et écriture dans le stockage local
├── screens/            Écrans, un dossier par onglet
├── widgets/            Composants d'interface partagés
├── theme/              Couleurs, typographie et thème Material
└── utils/              Mise en forme des nombres, dates et durées
```

La direction graphique est décrite dans [DESIGN.md](DESIGN.md).

## Crédits

Police [Barlow](https://github.com/jpt/barlow) de Jeremy Tribby, sous licence
SIL Open Font License (voir `assets/fonts/LICENSE-Barlow-OFL.txt`).
