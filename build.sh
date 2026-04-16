#!/bin/bash
set -e

# Se positionner dans le dossier du script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$DIR"

# Vérification et installation de Homebrew si nécessaire
if ! command -v brew &> /dev/null
then
    echo "Homebrew n'est pas installé. Installation..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Vérification et installation de xcodegen si nécessaire
if ! command -v xcodegen &> /dev/null
then
    echo "xcodegen n'est pas installé. Installation..."
    brew install xcodegen
fi

echo "Génération du projet Xcode avec xcodegen..."
xcodegen generate

echo "Compilation de l'application MdView..."
XCODE_PATH=$(ls -d /Applications/Xcode*.app | head -n 1)
if [ -n "$XCODE_PATH" ]; then
    export DEVELOPER_DIR="$XCODE_PATH/Contents/Developer"
    echo "Utilisation de Xcode situé à: $XCODE_PATH"
else
    echo "Avertissement: Xcode n'a pas été trouvé, xcodebuild risque d'échouer."
fi
xcodebuild -project MdView.xcodeproj -scheme MdView -configuration Release SYMROOT=build ARCHS="x86_64 arm64" ONLY_ACTIVE_ARCH=NO

echo "Création de l'image disque (.dmg)..."
APP_DIR="build/Release/MdView.app"
if [ ! -d "$APP_DIR" ]; then
    echo "Erreur: L'application MdView.app n'a pas été trouvée."
    exit 1
fi

DMG_NAME="MdView.dmg"
if [ -f "$DMG_NAME" ]; then
    rm "$DMG_NAME"
fi

# Création d'un dmg basique avec hdiutil
TMP_DIR=$(mktemp -d)
cp -r "$APP_DIR" "$TMP_DIR/"
ln -s /Applications "$TMP_DIR/Applications"
hdiutil create -volname "MdView" -srcfolder "$TMP_DIR" -ov -format UDZO "$DMG_NAME"

rm -rf "$TMP_DIR"

echo "Terminé avec succès. Le fichier $DMG_NAME a été créé."
