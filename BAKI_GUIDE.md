# 🥊 Guide Baki Hanma - Images & Partage

## 📸 Ajouter des images Baki

### Où mettre les images
Place tes images dans le dossier :
```
assets/images/
```

### Images recommandées à télécharger
Cherche sur Google Images ou Pinterest et télécharge :

1. **baki_banner.png** - Baki en pose de combat (pour les bannières)
2. **baki_victory.png** - Baki victorieux (pour les PRs)
3. **yujiro.png** - Yujiro Hanma (pour les séances difficiles)
4. **muscles.png** - Illustration de muscles style manga
5. **arena.png** - L'arène underground

### Noms suggérés pour les fichiers
```
assets/images/
├── baki_banner.png
├── baki_victory.png  
├── baki_pose.png
├── yujiro.png
├── workout_push.png
├── workout_pull.png
├── workout_legs.png
└── arena_bg.png
```

### ⚠️ Attention aux droits d'auteur
Pour une app personnelle entre potes, pas de souci.
Si tu veux publier sur le Play Store, utilise des images fan-art libres de droits ou crée les tiennes.

---

## 📱 Partager l'app avec ton pote

### Option 1 : APK direct (Le plus simple) ✅

1. **Build l'APK** :
```bash
cd /home/nicolas/Documents/APPNUNO/appnuno
flutter build apk --release
```

2. **Trouve l'APK** :
```
build/app/outputs/flutter-apk/app-release.apk
```

3. **Envoie-le** :
   - Par **Google Drive** / **Dropbox**
   - Par **Telegram** / **WhatsApp** (fichier)
   - Par **Bluetooth** / **Nearby Share**

4. **Sur le tel de ton pote** :
   - Télécharger l'APK
   - Aller dans Paramètres > Sécurité > "Sources inconnues" → Activer
   - Ouvrir l'APK et installer

---

### Option 2 : App Bundle pour le Play Store

Si tu veux la publier officiellement :

```bash
flutter build appbundle --release
```

Puis créer un compte Google Play Developer (25$ une fois) et publier.

---

### Option 3 : Test interne Play Store (Gratuit)

1. Créer un compte Play Console
2. Ajouter l'email de ton pote en "testeur interne"
3. Il reçoit un lien pour installer

---

## 🔧 Commandes utiles

### Build APK debug (rapide, pour tester)
```bash
flutter build apk --debug
```

### Build APK release (optimisé, plus petit)
```bash
flutter build apk --release
```

### Build avec un nom personnalisé
```bash
flutter build apk --release --build-name=1.0.0 --build-number=1
```

### Installer directement sur un téléphone connecté
```bash
flutter install
```

---

## 📝 Checklist avant de partager

- [ ] Tester l'app sur ton téléphone
- [ ] Vérifier que les données se sauvegardent bien
- [ ] Ajouter les images Baki
- [ ] Build en release
- [ ] Envoyer l'APK à ton pote

---

## 🎨 Personnaliser le nom et l'icône

### Changer le nom de l'app
Édite `android/app/src/main/AndroidManifest.xml` :
```xml
android:label="BAKI WORKOUT"
```

### Changer l'icône
1. Crée une icône 512x512 pixels
2. Utilise https://romannurik.github.io/AndroidAssetStudio/
3. Remplace les fichiers dans `android/app/src/main/res/`

Ou utilise le package `flutter_launcher_icons` :
```bash
flutter pub add flutter_launcher_icons --dev
```

---

**C'est parti champion ! 💪🔥**
