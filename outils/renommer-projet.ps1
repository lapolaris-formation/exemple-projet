<#
  Renomme le modèle ExempleProjet pour un nouveau projet : dossiers, fichiers, texte
  (solution, projets, espaces de noms, workflows, documentation) et identifiants (GUID).
  L'encodage de chaque fichier est conservé (avec ou sans BOM).

  Usage, à la racine du dépôt, dans PowerShell :
    powershell -ExecutionPolicy Bypass -File outils\renommer-projet.ps1 -Nouveau MonProjet

  À lancer une seule fois, sur une copie du modèle, avant le premier commit du nouveau projet.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z][A-Za-z0-9_]*$')]
    [string]$Nouveau
)

$ErrorActionPreference = 'Stop'
$ancien = 'ExempleProjet'
$racine = Split-Path -Parent $PSScriptRoot
$exclus = '\\(\.git|\.vs|bin|obj|packages|TestResults)(\\|$)'

if ($Nouveau -eq $ancien) { throw "Le nouveau nom doit être différent de $ancien." }
if (-not (Test-Path (Join-Path $racine "$ancien.sln"))) { throw "$ancien.sln introuvable : le projet a déjà été renommé ?" }

function Lire-Fichier($chemin) {
    $octets = [IO.File]::ReadAllBytes($chemin)
    if ($octets -contains 0) { return $null }                       # binaire : on n'y touche pas
    $bom = $octets.Length -ge 3 -and $octets[0] -eq 0xEF -and $octets[1] -eq 0xBB -and $octets[2] -eq 0xBF
    $debut = if ($bom) { 3 } else { 0 }
    return @{ Texte = [Text.Encoding]::UTF8.GetString($octets, $debut, $octets.Length - $debut); Bom = $bom }
}

function Ecrire-Fichier($chemin, $texte, $bom) {
    [IO.File]::WriteAllText($chemin, $texte, (New-Object Text.UTF8Encoding($bom)))
}

# La procédure parle du modèle d'origine : elle garde le nom ExempleProjet
$fichiers = Get-ChildItem $racine -Recurse -File -Force |
    Where-Object { $_.FullName -notmatch $exclus -and $_.FullName -ne $PSCommandPath -and $_.Name -ne 'procedure-complete.md' }

# 1. Nouveaux GUID pour les projets et les assemblies
$remplacements = @{}
foreach ($f in $fichiers | Where-Object { $_.Extension -eq '.vbproj' }) {
    $g = [regex]::Match([IO.File]::ReadAllText($f.FullName), '<ProjectGuid>(\{[0-9A-Fa-f-]+\})</ProjectGuid>').Groups[1].Value
    if ($g) { $remplacements[$g] = '{' + [guid]::NewGuid().ToString().ToUpper() + '}' }
}
foreach ($f in $fichiers | Where-Object { $_.Name -eq 'AssemblyInfo.vb' }) {
    $g = [regex]::Match([IO.File]::ReadAllText($f.FullName), 'Guid\("([0-9a-fA-F-]+)"\)').Groups[1].Value
    if ($g) { $remplacements[$g] = [guid]::NewGuid().ToString() }
}

# 2. Texte : ancien nom et GUID remplacés, encodage conservé
$modifies = 0
foreach ($f in $fichiers) {
    $contenu = Lire-Fichier $f.FullName
    if ($null -eq $contenu) { continue }
    $texte = $contenu.Texte.Replace($ancien, $Nouveau)
    foreach ($cle in $remplacements.Keys) { $texte = $texte.Replace($cle, $remplacements[$cle]) }
    if ($texte -ne $contenu.Texte) {
        Ecrire-Fichier $f.FullName $texte $contenu.Bom
        $modifies++
    }
}

# 3. Fichiers puis dossiers dont le nom contient l'ancien nom, du plus profond au moins profond
$aRenommer = Get-ChildItem $racine -Recurse -Force |
    Where-Object { $_.FullName -notmatch $exclus -and $_.Name -like "*$ancien*" } |
    Sort-Object { $_.FullName.Length } -Descending
foreach ($e in $aRenommer) {
    Rename-Item -LiteralPath $e.FullName -NewName ($e.Name.Replace($ancien, $Nouveau))
}

Write-Host "Fichiers modifiés : $modifies ; éléments renommés : $($aRenommer.Count) ; GUID renouvelés : $($remplacements.Count)"
Write-Host "Vérifier : git status, puis compiler la solution $Nouveau.sln."
