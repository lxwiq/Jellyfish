#!/bin/bash

# Script pour compiler l'application Flutter Jellyfish pour Windows
# en utilisant Docker depuis macOS

set -e

# Ajouter Docker au PATH si nécessaire
if ! command -v docker &> /dev/null; then
    export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

echo "🚀 Compilation de Jellyfish pour Windows avec Docker..."

# Répertoire de sortie pour les binaires Windows
OUTPUT_DIR="./build_windows"

# Créer le répertoire de sortie s'il n'existe pas
mkdir -p "$OUTPUT_DIR"

echo "🔨 Compilation de l'application Flutter pour Windows..."
# Utiliser directement l'image tauu/flutter-windows-builder
# Elle va automatiquement compiler et mettre les résultats dans C:\src\build_container
docker run --rm \
    -v "$(pwd):/c/src" \
    -v "$(pwd)/$OUTPUT_DIR:/c/src/build_container" \
    tauu/flutter-windows-builder:latest

echo "✅ Compilation terminée !"
echo "📁 Les fichiers compilés se trouvent dans : $OUTPUT_DIR"
echo ""
echo "Contenu du répertoire de sortie :"
ls -la "$OUTPUT_DIR"

echo ""
echo "🎉 Votre application Windows est prête !"
echo "Vous pouvez maintenant transférer le contenu de '$OUTPUT_DIR' vers un PC Windows pour l'exécuter."
