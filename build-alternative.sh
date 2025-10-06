#!/bin/bash

# Script alternatif pour compiler Flutter
# Utilise une image Linux au lieu de Windows (compatible avec Mac M1/M2)

set -e

echo "🚀 Compilation alternative de Jellyfish avec Docker (Linux)..."
echo "⚠️  Note: Cette méthode crée un build Linux, pas Windows"
echo "⚠️  Pour un vrai build Windows, utilisez GitHub Actions"

# Ajouter Docker au PATH si nécessaire
if ! command -v docker &> /dev/null; then
    export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

# Nom de l'image Docker
IMAGE_NAME="jellyfish-linux-builder"

# Répertoire de sortie pour les binaires
OUTPUT_DIR="./build_linux"

# Créer le répertoire de sortie s'il n'existe pas
mkdir -p "$OUTPUT_DIR"

echo "📦 Construction de l'image Docker Linux..."
docker build -f Dockerfile.linux-cross -t "$IMAGE_NAME" .

echo "🔨 Compilation de l'application Flutter..."
docker run --rm \
    -v "$(pwd)/$OUTPUT_DIR:/output" \
    "$IMAGE_NAME" \
    bash -c "/build.sh && cp -r build/linux/x64/release/bundle/* /output/"

echo "✅ Compilation terminée !"
echo "📁 Les fichiers compilés se trouvent dans : $OUTPUT_DIR"
echo ""
echo "Contenu du répertoire de sortie :"
ls -la "$OUTPUT_DIR"

echo ""
echo "⚠️  IMPORTANT: Ce build est pour Linux, pas Windows !"
echo "🎯 Pour un vrai build Windows, utilisez une de ces méthodes :"
echo "   1. GitHub Actions (recommandé) - voir .github/workflows/build-windows.yml"
echo "   2. Un PC Windows avec Docker"
echo "   3. Une VM Windows"
