# Script PowerShell de build Windows avec création de l'installateur
# Ce script compile l'application Flutter pour Windows et génère un installateur avec Inno Setup

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Jellyfish - Build Windows Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Flutter est installé
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "[ERREUR] Flutter n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Red
    exit 1
}

# Vérifier que Inno Setup est installé
$innoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (-not (Test-Path $innoSetupPath)) {
    Write-Host "[AVERTISSEMENT] Inno Setup n'est pas installé à l'emplacement par défaut" -ForegroundColor Yellow
    Write-Host "Veuillez installer Inno Setup depuis: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    Write-Host "Ou modifier le chemin dans ce script" -ForegroundColor Yellow
    
    # Chercher dans d'autres emplacements communs
    $alternativePaths = @(
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        "C:\Program Files (x86)\Inno Setup 5\ISCC.exe",
        "C:\Program Files\Inno Setup 5\ISCC.exe"
    )
    
    $found = $false
    foreach ($path in $alternativePaths) {
        if (Test-Path $path) {
            $innoSetupPath = $path
            $found = $true
            Write-Host "Trouvé à: $path" -ForegroundColor Green
            break
        }
    }
    
    if (-not $found) {
        $innoSetupPath = Read-Host "Entrez le chemin complet vers ISCC.exe"
        if (-not (Test-Path $innoSetupPath)) {
            Write-Host "[ERREUR] Chemin invalide" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
Write-Host "[1/5] Nettoyage des builds précédents..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERREUR] Échec du nettoyage" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/5] Récupération des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERREUR] Échec de la récupération des dépendances" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/5] Build de l'application Windows (Release)..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERREUR] Échec du build Windows" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/5] Création du dossier de sortie pour l'installateur..." -ForegroundColor Yellow
$installerDir = "build\windows\installer"
if (-not (Test-Path $installerDir)) {
    New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
}

Write-Host ""
Write-Host "[5/5] Génération de l'installateur avec Inno Setup..." -ForegroundColor Yellow
& $innoSetupPath "windows\installer.iss"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERREUR] Échec de la génération de l'installateur" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Build terminé avec succès !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "L'installateur a été créé dans:" -ForegroundColor Cyan
Write-Host "  $installerDir\" -ForegroundColor White
Write-Host ""

# Lister les fichiers .exe créés
$installers = Get-ChildItem -Path $installerDir -Filter "*.exe"
foreach ($installer in $installers) {
    Write-Host "  - $($installer.Name)" -ForegroundColor Green
    Write-Host "    Taille: $([math]::Round($installer.Length / 1MB, 2)) MB" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

