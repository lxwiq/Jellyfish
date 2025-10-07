# Script PowerShell pour créer une nouvelle release Jellyfish
# Usage: .\scripts\create-release.ps1 1.2.3

param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

# Fonction pour afficher les messages
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
    exit 1
}

# Vérifier le format de la version
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "Format de version invalide. Utilisez: MAJOR.MINOR.PATCH (ex: 1.2.3)"
}

$Tag = "v$Version"

Write-Host ""
Write-Info "🚀 Création de la release $Tag"
Write-Host ""

# Vérifier que nous sommes sur la branche main
$CurrentBranch = git branch --show-current
if ($CurrentBranch -ne "main") {
    Write-Warning "Vous n'êtes pas sur la branche main (branche actuelle: $CurrentBranch)"
    $Continue = Read-Host "Continuer quand même ? (y/N)"
    if ($Continue -ne "y" -and $Continue -ne "Y") {
        Write-Error "Annulé"
    }
}

# Vérifier qu'il n'y a pas de modifications non commitées
$GitStatus = git status --porcelain
if ($GitStatus) {
    Write-Error "Il y a des modifications non commitées. Veuillez les commiter ou les stasher."
}

# Vérifier que le tag n'existe pas déjà
$TagExists = git tag -l $Tag
if ($TagExists) {
    Write-Error "Le tag $Tag existe déjà"
}

# Mettre à jour la version dans pubspec.yaml
Write-Info "Mise à jour de pubspec.yaml..."

$PubspecContent = Get-Content pubspec.yaml -Raw
$CurrentBuild = [int]($PubspecContent -match 'version: \d+\.\d+\.\d+\+(\d+)' | Out-Null; $Matches[1])
$NewBuild = $CurrentBuild + 1

$PubspecContent = $PubspecContent -replace 'version: \d+\.\d+\.\d+\+\d+', "version: $Version+$NewBuild"
$PubspecContent | Set-Content pubspec.yaml -NoNewline

Write-Success "Version mise à jour: $Version+$NewBuild"

# Mettre à jour la version dans windows/installer.iss
Write-Info "Mise à jour de windows/installer.iss..."

$InstallerContent = Get-Content windows/installer.iss -Raw
$InstallerContent = $InstallerContent -replace '#define MyAppVersion "\d+\.\d+\.\d+"', "#define MyAppVersion `"$Version`""
$InstallerContent | Set-Content windows/installer.iss -NoNewline

Write-Success "Installer Windows mis à jour"

# Afficher les changements
Write-Host ""
Write-Info "Changements à commiter:"
git diff pubspec.yaml windows/installer.iss

Write-Host ""
$CommitChanges = Read-Host "Commiter ces changements ? (Y/n)"
if ($CommitChanges -ne "n" -and $CommitChanges -ne "N") {
    git add pubspec.yaml windows/installer.iss
    git commit -m "chore: bump version to $Version"
    Write-Success "Changements commitées"
} else {
    Write-Warning "Changements non commitées"
}

# Demander confirmation pour pousser
Write-Host ""
$PushChanges = Read-Host "Pousser les changements et créer le tag $Tag ? (Y/n)"
if ($PushChanges -ne "n" -and $PushChanges -ne "N") {
    # Pousser les commits
    Write-Info "Push des commits..."
    git push origin main
    Write-Success "Commits poussés"
    
    # Créer et pousser le tag
    Write-Info "Création du tag $Tag..."
    git tag -a $Tag -m "Release $Version"
    
    Write-Info "Push du tag..."
    git push origin $Tag
    Write-Success "Tag $Tag créé et poussé"
    
    Write-Host ""
    Write-Success "✨ Release $Tag créée avec succès !"
    Write-Host ""
    Write-Info "Le workflow GitHub Actions va maintenant:"
    Write-Host "  1. Builder l'APK Android"
    Write-Host "  2. Builder l'installateur Windows"
    Write-Host "  3. Créer la release GitHub"
    Write-Host ""
    Write-Info "Suivez la progression sur:"
    Write-Host "  https://github.com/lxwiq/Jellyfish/actions"
    Write-Host ""
    Write-Info "Une fois terminé, éditez la release pour ajouter vos notes:"
    Write-Host "  https://github.com/lxwiq/Jellyfish/releases"
    Write-Host ""
} else {
    Write-Warning "Tag non créé. Vous pouvez le faire manuellement avec:"
    Write-Host "  git tag -a $Tag -m 'Release $Version'"
    Write-Host "  git push origin $Tag"
}

