# 🐛 Guide de débogage - Page des téléchargements

## Problèmes identifiés

1. **Les barres de progression ne s'affichent pas**
2. **Les mises à jour ne sont pas en temps réel**

## ✅ Corrections apportées

### 1. Correction du StreamProvider

**Problème** : Le `downloadedItemStreamProvider` utilisait `ref.watch` dans un générateur async, ce qui ne fonctionne pas.

**Solution** : Utilisation de `Stream.multi` pour créer un stream personnalisé qui combine l'état initial et les mises à jour.

```dart
final downloadedItemStreamProvider = StreamProvider.family<DownloadedItem?, String>(
  (ref, downloadId) {
    final storageService = ref.watch(offlineStorageServiceProvider);
    final service = ref.watch(offlineDownloadServiceProvider);
    
    return Stream.multi((controller) async {
      // État initial
      final initialItem = await storageService.getDownloadedItem(downloadId);
      if (!controller.isClosed) {
        controller.add(initialItem);
      }
      
      // Écouter les mises à jour
      final subscription = service.progressStream.listen(
        (updatedItem) {
          if (updatedItem.id == downloadId && !controller.isClosed) {
            controller.add(updatedItem);
          }
        },
      );
      
      controller.onCancel = () => subscription.cancel();
    });
  },
);
```

### 2. Ajout d'un polling automatique

**Problème** : Le stream peut ne pas émettre assez souvent ou être manqué.

**Solution** : Timer qui rafraîchit les listes toutes les 2 secondes.

```dart
_refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
  if (mounted) {
    ref.invalidate(activeDownloadsProvider);
    ref.invalidate(downloadStatsProvider);
  }
});
```

### 3. Amélioration de la barre de progression

**Changements** :
- Affichage pour plus de statuts (pending, paused, failed avec progression)
- Hauteur augmentée (minHeight: 6)
- Coins arrondis
- Couleurs adaptatives (rouge=failed, orange=paused, bleu=downloading)
- Affichage du pourcentage et de la vitesse

### 4. Ajout de logs de débogage

**Dans le service** :
```dart
print('📤 Émission update: ${updatedItem.title} - ${updatedItem.progressPercentage}');
```

**Dans l'écran** :
```dart
print('📥 Update reçue: ${item.title} - ${item.progressPercentage}');
```

## 🔍 Comment déboguer

### Étape 1 : Vérifier que le service émet des mises à jour

1. Démarrer un téléchargement
2. Regarder la console pour les logs `📤 Émission update:`
3. Si vous ne voyez pas ces logs, le problème est dans le service de téléchargement

**Vérifications** :
- Le service `OfflineDownloadService` est-il bien initialisé ?
- Le `FileDownloader().updates.listen(_handleDownloadUpdate)` est-il appelé ?
- Le mapping `_taskIdMapping` contient-il bien le taskId ?

### Étape 2 : Vérifier que l'écran reçoit les mises à jour

1. Regarder la console pour les logs `📥 Update reçue:`
2. Si vous voyez `📤` mais pas `📥`, le problème est dans le provider

**Vérifications** :
- Le `downloadProgressListenerProvider` est-il bien watch dans l'écran ?
- Le stream `progressStream` est-il bien écouté ?

### Étape 3 : Vérifier que les cartes se mettent à jour

1. Ajouter un log dans `DownloadProgressCard.build()` :
```dart
print('🔄 Card rebuild: ${currentItem.title} - ${currentItem.progressPercentage}');
```

2. Si la carte ne se rebuild pas, le `downloadedItemStreamProvider` ne fonctionne pas

### Étape 4 : Vérifier que la barre de progression s'affiche

1. Vérifier que la condition est remplie :
```dart
if (currentItem.isDownloading || 
    currentItem.isPaused || 
    currentItem.isPending ||
    (currentItem.isFailed && currentItem.progress > 0))
```

2. Ajouter un log pour voir le statut :
```dart
print('Status: ${currentItem.status}, Progress: ${currentItem.progress}');
```

## 🧪 Tests à effectuer

### Test 1 : Démarrer un téléchargement

1. Aller sur un film/série
2. Cliquer sur le bouton de téléchargement
3. Choisir une qualité
4. Aller dans l'onglet "Downloads"

**Résultat attendu** :
- L'item apparaît dans l'onglet "Active"
- Une barre de progression s'affiche
- La barre se remplit progressivement
- Le pourcentage s'actualise
- La vitesse s'affiche (si disponible)

### Test 2 : Mettre en pause

1. Cliquer sur le bouton pause
2. Observer les changements

**Résultat attendu** :
- Le statut passe à "Paused"
- La barre devient orange
- Le bouton change en "play"

### Test 3 : Reprendre

1. Cliquer sur le bouton play
2. Observer les changements

**Résultat attendu** :
- Le statut passe à "Downloading"
- La barre redevient bleue
- La progression reprend

### Test 4 : Téléchargement terminé

1. Attendre la fin du téléchargement

**Résultat attendu** :
- Notification "downloaded successfully"
- L'item passe dans l'onglet "Completed"
- La barre de progression disparaît

## 🔧 Solutions alternatives si ça ne fonctionne toujours pas

### Solution 1 : Forcer le rebuild avec un key

Dans `downloads_screen.dart`, ajouter une key unique pour chaque carte :

```dart
return DownloadProgressCard(
  key: ValueKey(downloads[index].id),
  item: downloads[index],
);
```

### Solution 2 : Utiliser un AutoRefresh

Créer un provider qui se rafraîchit automatiquement :

```dart
final autoRefreshProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (count) => count);
});

// Dans l'écran
ref.watch(autoRefreshProvider);
```

### Solution 3 : Utiliser un StateNotifier

Créer un `StateNotifier` qui gère l'état des téléchargements :

```dart
class DownloadsNotifier extends StateNotifier<List<DownloadedItem>> {
  DownloadsNotifier(this._service) : super([]) {
    _init();
  }
  
  final OfflineDownloadService _service;
  StreamSubscription? _subscription;
  
  void _init() {
    _subscription = _service.progressStream.listen((item) {
      // Mettre à jour la liste
      state = [...state];
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

## 📝 Checklist de vérification

- [ ] Les logs `📤 Émission update:` apparaissent dans la console
- [ ] Les logs `📥 Update reçue:` apparaissent dans la console
- [ ] Le timer de 2 secondes rafraîchit les listes
- [ ] La barre de progression s'affiche pour les téléchargements actifs
- [ ] La barre de progression s'anime
- [ ] Le pourcentage s'actualise
- [ ] Les statuts changent correctement
- [ ] Les items changent d'onglet automatiquement
- [ ] Les notifications s'affichent

## 🆘 Si rien ne fonctionne

1. **Vérifier que le téléchargement démarre vraiment**
   - Regarder les logs du service
   - Vérifier dans la base de données SQLite

2. **Vérifier que le FileDownloader fonctionne**
   - Tester avec un téléchargement simple
   - Vérifier les permissions

3. **Simplifier l'approche**
   - Retirer le stream
   - Utiliser uniquement le polling toutes les 2 secondes
   - Ça devrait au moins fonctionner même si ce n'est pas en temps réel

4. **Contacter le support**
   - Fournir les logs complets
   - Décrire le comportement observé
   - Indiquer la plateforme (iOS/Android/macOS)

