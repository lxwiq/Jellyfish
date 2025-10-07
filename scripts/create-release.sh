#!/bin/bash

# Script pour créer une nouvelle release Jellyfish
# Usage: ./scripts/create-release.sh 1.2.3

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

# Vérifier qu'une version est fournie
if [ -z "$1" ]; then
    error "Usage: ./scripts/create-release.sh <version>\nExemple: ./scripts/create-release.sh 1.2.3"
fi

VERSION=$1
TAG="v${VERSION}"

# Vérifier le format de la version
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Format de version invalide. Utilisez: MAJOR.MINOR.PATCH (ex: 1.2.3)"
fi

echo ""
info "🚀 Création de la release ${TAG}"
echo ""

# Vérifier que nous sommes sur la branche main
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    warning "Vous n'êtes pas sur la branche main (branche actuelle: ${CURRENT_BRANCH})"
    read -p "Continuer quand même ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Annulé"
    fi
fi

# Vérifier qu'il n'y a pas de modifications non commitées
if ! git diff-index --quiet HEAD --; then
    error "Il y a des modifications non commitées. Veuillez les commiter ou les stasher."
fi

# Vérifier que le tag n'existe pas déjà
if git rev-parse "$TAG" >/dev/null 2>&1; then
    error "Le tag ${TAG} existe déjà"
fi

# Mettre à jour la version dans pubspec.yaml
info "Mise à jour de pubspec.yaml..."

# Extraire le build number actuel
CURRENT_BUILD=$(grep -E "^version:" pubspec.yaml | sed -E 's/version: [0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))

# Mettre à jour la version
sed -i.bak -E "s/^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/version: ${VERSION}+${NEW_BUILD}/" pubspec.yaml
rm pubspec.yaml.bak

success "Version mise à jour: ${VERSION}+${NEW_BUILD}"

# Mettre à jour la version dans windows/installer.iss
info "Mise à jour de windows/installer.iss..."
sed -i.bak -E "s/#define MyAppVersion \"[0-9]+\.[0-9]+\.[0-9]+\"/#define MyAppVersion \"${VERSION}\"/" windows/installer.iss
rm windows/installer.iss.bak

success "Installer Windows mis à jour"

# Afficher les changements
echo ""
info "Changements à commiter:"
git diff pubspec.yaml windows/installer.iss

echo ""
read -p "Commiter ces changements ? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git add pubspec.yaml windows/installer.iss
    git commit -m "chore: bump version to ${VERSION}"
    success "Changements commitées"
else
    warning "Changements non commitées"
fi

# Demander confirmation pour pousser
echo ""
read -p "Pousser les changements et créer le tag ${TAG} ? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    # Pousser les commits
    info "Push des commits..."
    git push origin main
    success "Commits poussés"
    
    # Créer et pousser le tag
    info "Création du tag ${TAG}..."
    git tag -a "$TAG" -m "Release ${VERSION}"
    
    info "Push du tag..."
    git push origin "$TAG"
    success "Tag ${TAG} créé et poussé"
    
    echo ""
    success "✨ Release ${TAG} créée avec succès !"
    echo ""
    info "Le workflow GitHub Actions va maintenant:"
    echo "  1. Builder l'APK Android"
    echo "  2. Builder l'installateur Windows"
    echo "  3. Créer la release GitHub"
    echo ""
    info "Suivez la progression sur:"
    echo "  https://github.com/lxwiq/Jellyfish/actions"
    echo ""
    info "Une fois terminé, éditez la release pour ajouter vos notes:"
    echo "  https://github.com/lxwiq/Jellyfish/releases"
    echo ""
else
    warning "Tag non créé. Vous pouvez le faire manuellement avec:"
    echo "  git tag -a ${TAG} -m 'Release ${VERSION}'"
    echo "  git push origin ${TAG}"
fi

