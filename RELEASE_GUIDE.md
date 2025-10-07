# 🚀 Guide de Publication des Releases

Ce guide explique comment publier une nouvelle version de Jellyfish avec le système de mise à jour automatique.

## 📋 Prérequis

- Accès push au repository GitHub
- Git configuré localement
- Toutes les modifications commitées

## 🔄 Processus de Release

### 1. Préparer la version

Mettez à jour le numéro de version dans `pubspec.yaml` :

```yaml
version: 1.2.3+10
#        │ │ │  └─ Build number (incrémente à chaque build)
#        │ │ └──── Patch (corrections de bugs)
#        │ └────── Minor (nouvelles fonctionnalités)
#        └──────── Major (changements majeurs)
```

### 2. Commiter les changements

```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.2.3"
git push origin main
```

### 3. Créer et pousser le tag

```bash
# Créer le tag (doit commencer par 'v')
git tag v1.2.3

# Pousser le tag vers GitHub
git push origin v1.2.3
```

### 4. Workflow automatique

Une fois le tag poussé, GitHub Actions va automatiquement :

1. ✅ Builder l'APK Android
2. ✅ Builder l'installateur Windows
3. ✅ Créer une release GitHub
4. ✅ Uploader les fichiers

Vous pouvez suivre la progression dans l'onglet **Actions** de votre repository GitHub.

### 5. Finaliser la release

Une fois le workflow terminé :

1. Allez dans **Releases** sur GitHub
2. Éditez la release créée
3. Ajoutez vos notes de version détaillées
4. Publiez la release

## 📱 Système de Mise à Jour

### Architecture

```
┌─────────────────────────────────────────┐
│  Système de mise à jour Jellyfish       │
├─────────────────────────────────────────┤
│                                          │
│  1. Shorebird (Code Push)                │
│     → Mises à jour Dart/Flutter          │
│     → Automatique en arrière-plan        │
│     → Pas de redémarrage nécessaire      │
│                                          │
│  2. GitHub Releases (Natif)              │
│     → Mises à jour complètes             │
│     → Android: APK                       │
│     → Windows: Installer                 │
│     → Vérification manuelle ou auto      │
│                                          │
└─────────────────────────────────────────┘
```

### Quand utiliser chaque type ?

**Shorebird (Code Push)** :
- Corrections de bugs mineurs
- Ajustements UI
- Changements de logique Dart
- Mises à jour fréquentes

**GitHub Releases (Natif)** :
- Nouvelles fonctionnalités majeures
- Changements de dépendances natives
- Mises à jour de version Flutter
- Changements de permissions
- Mises à jour mensuelles/trimestrielles

## 🔧 Configuration

### Variables d'environnement GitHub

Aucune variable secrète n'est nécessaire ! Le workflow utilise `GITHUB_TOKEN` qui est automatiquement fourni.

### Personnalisation du workflow

Le fichier `.github/workflows/release.yml` peut être personnalisé :

- **Version de Flutter** : Modifiez `flutter-version: '3.24.0'`
- **Plateformes** : Ajoutez des jobs pour macOS, Linux, etc.
- **Nom des fichiers** : Modifiez les étapes de renommage

## 📝 Exemple de Notes de Version

```markdown
## 🎉 Nouveautés

- ✨ Ajout du support des sous-titres personnalisés
- 🎨 Nouvelle interface pour les paramètres
- 🚀 Amélioration des performances de lecture

## 🐛 Corrections

- 🔧 Correction du crash au démarrage sur Android 12
- 🔧 Résolution du problème de synchronisation

## 🔄 Améliorations

- ⚡ Temps de chargement réduit de 30%
- 📱 Meilleure gestion de la mémoire
```

## 🎯 Checklist de Release

Avant de créer une release :

- [ ] Tests effectués sur Android
- [ ] Tests effectués sur Windows
- [ ] Version mise à jour dans `pubspec.yaml`
- [ ] Changelog préparé
- [ ] Commits poussés sur `main`
- [ ] Tag créé et poussé
- [ ] Workflow GitHub Actions réussi
- [ ] Notes de version ajoutées
- [ ] Release publiée

## 🆘 Dépannage

### Le workflow échoue

1. Vérifiez les logs dans l'onglet **Actions**
2. Assurez-vous que le tag commence par `v`
3. Vérifiez que `pubspec.yaml` est valide

### L'APK ne se build pas

- Vérifiez la version de Flutter dans le workflow
- Assurez-vous que toutes les dépendances sont compatibles

### L'installateur Windows ne se crée pas

- Vérifiez que `windows/installer.iss` existe
- Assurez-vous que la version est correcte dans le fichier

### Les utilisateurs ne voient pas la mise à jour

- Vérifiez que la release est publiée (pas en draft)
- Assurez-vous que le tag suit le format `vX.Y.Z`
- Vérifiez que les assets sont bien uploadés

## 📊 Suivi des Versions

### Stratégie de versioning

Nous utilisons [Semantic Versioning](https://semver.org/) :

- **MAJOR** (1.x.x) : Changements incompatibles
- **MINOR** (x.1.x) : Nouvelles fonctionnalités compatibles
- **PATCH** (x.x.1) : Corrections de bugs

### Fréquence recommandée

- **Shorebird patches** : Quotidien/Hebdomadaire
- **Releases natives** : Mensuel/Trimestriel

## 🔐 Sécurité

### Signature des builds

**Android** : Configurez la signature dans `android/app/build.gradle.kts`

**Windows** : Utilisez un certificat de signature de code (optionnel mais recommandé)

## 📞 Support

Pour toute question sur le processus de release :

1. Consultez les logs GitHub Actions
2. Vérifiez ce guide
3. Ouvrez une issue sur GitHub

