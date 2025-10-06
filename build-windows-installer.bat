@echo off
REM Script de build Windows avec création de l'installateur
REM Ce script compile l'application Flutter pour Windows et génère un installateur avec Inno Setup

echo ========================================
echo   Jellyfish - Build Windows Installer
echo ========================================
echo.

REM Vérifier que Flutter est installé
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Flutter n'est pas installé ou n'est pas dans le PATH
    exit /b 1
)

REM Vérifier que Inno Setup est installé
set INNO_SETUP="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %INNO_SETUP% (
    echo [AVERTISSEMENT] Inno Setup n'est pas installé à l'emplacement par défaut
    echo Veuillez installer Inno Setup depuis: https://jrsoftware.org/isdl.php
    echo Ou modifier le chemin dans ce script
    set /p INNO_SETUP="Entrez le chemin complet vers ISCC.exe: "
)

echo.
echo [1/5] Nettoyage des builds précédents...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Échec du nettoyage
    exit /b 1
)

echo.
echo [2/5] Récupération des dépendances...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Échec de la récupération des dépendances
    exit /b 1
)

echo.
echo [3/5] Build de l'application Windows (Release)...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Échec du build Windows
    exit /b 1
)

echo.
echo [4/5] Création du dossier de sortie pour l'installateur...
if not exist "build\windows\installer" mkdir "build\windows\installer"

echo.
echo [5/5] Génération de l'installateur avec Inno Setup...
%INNO_SETUP% "windows\installer.iss"
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Échec de la génération de l'installateur
    exit /b 1
)

echo.
echo ========================================
echo   Build terminé avec succès !
echo ========================================
echo.
echo L'installateur a été créé dans:
echo   build\windows\installer\
echo.
dir /b build\windows\installer\*.exe
echo.
pause

