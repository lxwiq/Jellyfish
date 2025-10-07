# 🔄 Système de Mises à Jour Jellyfish

Jellyfish dispose d'un système de mise à jour double pour vous offrir la meilleure expérience :

## 📱 Types de Mises à Jour

### 1. Mises à jour Code (Shorebird)

**Automatiques et transparentes**

- ✅ Téléchargées automatiquement en arrière-plan
- ✅ Appliquées au prochain démarrage
- ✅ Pas de téléchargement manuel
- ✅ Très rapides (quelques Ko)
- ✅ Corrections de bugs et améliorations mineures

**Comment ça marche ?**

L'application vérifie automatiquement les mises à jour au démarrage. Si une mise à jour est disponible, elle est téléchargée en arrière-plan et appliquée au prochain redémarrage.

### 2. Mises à jour Natives (GitHub Releases)

**Mises à jour majeures**

- 📦 Nouvelles fonctionnalités importantes
- 📦 Changements de version majeure
- 📦 Nécessitent une installation manuelle
- 📦 Taille plus importante (plusieurs Mo)

**Comment ça marche ?**

L'application vous notifie quand une nouvelle version majeure est disponible. Vous pouvez alors :

1. **Télécharger** : L'application télécharge automatiquement la mise à jour
2. **Installer** : 
   - **Android** : Ouvre l'installateur APK
   - **Windows** : Lance l'installateur qui remplace l'ancienne version

## ⚙️ Configuration

### Paramètres de Mise à Jour

Allez dans **Paramètres > Mises à jour** pour configurer :

#### Vérification automatique
- **Activé** : Vérifie les mises à jour au démarrage
- **Désactivé** : Vérification manuelle uniquement

#### Notifications
- **Activé** : Vous êtes notifié des nouvelles versions
- **Désactivé** : Pas de notifications

### Vérification Manuelle

Vous pouvez vérifier manuellement les mises à jour :

1. Ouvrez **Paramètres**
2. Allez dans **Mises à jour**
3. Appuyez sur **Vérifier maintenant**

L'application vérifiera :
1. D'abord les mises à jour Shorebird (rapides)
2. Ensuite les mises à jour natives (majeures)

## 📥 Installation des Mises à Jour

### Android

1. L'application télécharge l'APK
2. Une notification apparaît
3. Appuyez sur la notification
4. Autorisez l'installation depuis cette source
5. Installez la mise à jour
6. L'ancienne version est automatiquement remplacée

**Note** : Vous devrez peut-être autoriser l'installation depuis des sources inconnues la première fois.

### Windows

1. L'application télécharge l'installateur
2. L'installateur se lance automatiquement
3. L'ancienne version est désinstallée automatiquement
4. La nouvelle version est installée
5. L'application redémarre

**Note** : L'installateur peut demander des droits administrateur.

## 🔔 Notifications de Mise à Jour

### Quand êtes-vous notifié ?

- Au démarrage de l'application (si activé)
- Quand une nouvelle version majeure est disponible
- Jamais pour les mises à jour Shorebird (automatiques)

### Types de Notifications

**Mise à jour disponible** 📢
- Une nouvelle version est disponible
- Vous pouvez choisir de télécharger maintenant ou plus tard

**Téléchargement en cours** ⏬
- La mise à jour est en cours de téléchargement
- Une barre de progression s'affiche

**Prêt à installer** ✅
- Le téléchargement est terminé
- Appuyez pour installer

## ❓ Questions Fréquentes

### Pourquoi deux systèmes de mise à jour ?

- **Shorebird** : Pour les corrections rapides et fréquentes
- **GitHub** : Pour les grosses mises à jour moins fréquentes

Cela permet d'avoir le meilleur des deux mondes : rapidité ET fonctionnalités.

### Les mises à jour sont-elles obligatoires ?

Non ! Vous pouvez :
- Désactiver la vérification automatique
- Ignorer une version spécifique
- Choisir quand installer

### Puis-je revenir à une version précédente ?

Oui, téléchargez simplement l'ancienne version depuis les [Releases GitHub](https://github.com/lxwiq/Jellyfish/releases).

### Combien de données consomment les mises à jour ?

- **Shorebird** : Quelques Ko à quelques Mo
- **Natives** : 20-50 Mo selon la plateforme

**Conseil** : Activez "WiFi uniquement" dans les paramètres de téléchargement.

### Que se passe-t-il si je refuse une mise à jour ?

- **Shorebird** : Appliquée automatiquement au prochain démarrage
- **Native** : Vous pouvez l'ignorer définitivement ou la reporter

### Comment savoir quelle version j'ai ?

Allez dans **Paramètres > Mises à jour** pour voir :
- Version actuelle
- Numéro de build
- Dernière vérification

### Les mises à jour sont-elles sûres ?

Oui ! Toutes les mises à jour proviennent de sources officielles :
- **Shorebird** : Serveurs Shorebird sécurisés
- **GitHub** : Releases officielles du repository

### Puis-je désactiver complètement les mises à jour ?

Oui, désactivez :
- Vérification automatique
- Notifications

Vous pourrez toujours vérifier manuellement.

## 🛠️ Dépannage

### La vérification échoue

1. Vérifiez votre connexion Internet
2. Réessayez plus tard
3. Vérifiez manuellement

### Le téléchargement échoue

1. Vérifiez l'espace de stockage disponible
2. Vérifiez votre connexion Internet
3. Réessayez le téléchargement

### L'installation échoue (Android)

1. Autorisez l'installation depuis des sources inconnues
2. Vérifiez l'espace de stockage
3. Redémarrez l'appareil

### L'installation échoue (Windows)

1. Fermez complètement l'application
2. Lancez l'installateur en tant qu'administrateur
3. Désinstallez manuellement l'ancienne version si nécessaire

## 📊 Historique des Mises à Jour

Consultez l'historique complet des versions sur :
[GitHub Releases](https://github.com/lxwiq/Jellyfish/releases)

Chaque release contient :
- Notes de version détaillées
- Liste des nouveautés
- Corrections de bugs
- Fichiers de téléchargement

