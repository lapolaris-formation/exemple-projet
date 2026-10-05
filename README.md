# ExempleProjet : modèle de projet VB.NET avec pipeline de sécurité

Modèle de départ pour une application Windows Forms en **VB.NET, .NET Framework 4.8, paquets en `packages.config`**,
avec tout ce qu'il faut pour travailler en équipe sur GitHub et préparer le Cyber Resilience Act :
workflows d'intégration continue, analyse de code, détection de secrets, Dependabot, release avec SBOM
et attestation de provenance, modèles d'issue et de pull request, charte Git.

L'application elle-même est vide : un formulaire, et un module `Calculs` d'exemple avec ses deux tests,
à remplacer par le vrai code.

## Contenu

| Élément | Rôle |
|---|---|
| `ExempleProjet/` | l'application (WinForms, .NET Framework 4.8) |
| `tests/ExempleProjet.Tests/` | les tests (xUnit, `packages.config`), exécutés par `vstest.console` |
| `.github/workflows/build.yml` | compile avec MSBuild, vérifie que chaque DLL livrée se charge |
| `.github/workflows/tests.yml` | lance les tests, publie les résultats en artefact |
| `.github/workflows/code-scanning.yml` | analyseurs Roslyn et DevSkim, résultats dans Code scanning (CodeQL ne lit pas le VB) |
| `.github/workflows/secrets.yml` | Gitleaks sur tout l'historique, avec les règles de `.gitleaks.toml` |
| `.github/workflows/dependency-review.yml` | bloque une pull request qui ajoute un paquet vulnérable |
| `.github/workflows/verification-pr.yml` | exige un lien vers une issue et un titre au format des commits |
| `.github/workflows/release.yml` | sur un tag `vX.Y.Z` : binaire, SBOM, attestation de provenance, release |
| `.github/dependabot.yml` | mises à jour NuGet et GitHub Actions, chaque lundi |
| `.github/CODEOWNERS`, modèles d'issue et de PR | revue obligatoire, formulaires communs |
| `SECURITY.md` | politique de signalement des vulnérabilités |
| `docs/charte-git.md` | les règles de l'équipe, à adapter et adopter |
| `CHECKLIST.md` | la mise en place du dépôt, étape par étape |

## Réutiliser le modèle pour un nouveau projet

1. **Copier** le dossier, sans `bin`, `obj`, `packages` ni `.vs`.
2. **Renommer** le projet dans Visual Studio (solution, projet, espace de noms), ou remplacer `ExempleProjet`
   dans les noms de fichiers et dans `ExempleProjet.sln`, les deux `.vbproj` et `AssemblyInfo.vb`.
3. **Adapter les lignes `env:`** en tête de chaque workflow : c'est le seul endroit où le nom du projet apparaît.

   ```yaml
   env:
     SOLUTION: ExempleProjet.sln
     PROJET: ExempleProjet
   ```

4. **Remplacer les repères** : `ORGANISATION` dans `.github/CODEOWNERS`, les valeurs entre `< >`
   dans `SECURITY.md` et `docs/charte-git.md`.
5. **Lister les dossiers** qui contiennent un `packages.config` dans `.github/dependabot.yml`.
6. **Suivre `CHECKLIST.md`** : création du dépôt, réglages GitHub, contrôles requis.

Les fichiers YAML s'indentent avec **deux espaces**, jamais de tabulation (réglé par `.editorconfig`).
Ne copiez jamais un workflow depuis un PDF : copiez le fichier.

## Compiler et tester en local

Depuis la racine, dans l'invite de commandes développeur de Visual Studio 2022 :

```powershell
msbuild ExempleProjet.sln -t:restore -p:RestorePackagesConfig=true
msbuild ExempleProjet.sln -p:Configuration=Release
vstest.console tests\ExempleProjet.Tests\bin\Release\ExempleProjet.Tests.dll
```

`dotnet build` et `dotnet test` ne conviennent pas à ce format de projet.

## Composants tiers hors NuGet

Une DLL de fournisseur copiée dans le projet sans NuGet est invisible pour Dependabot et pour CycloneDX.
Elle se déclare dans `.github/outils/composants-hors-nuget.json` : le workflow `release` l'ajoute au SBOM,
avec son empreinte SHA-256.

| Fichier | Version | Éditeur | Licence |
|---|---|---|---|
| aucun pour l'instant | | | |

## Ce qui est payant sur un dépôt privé

| Fonction | Dépôt public | Dépôt privé |
|---|---|---|
| Dependabot, graphe de dépendances, workflows | gratuit | gratuit |
| Affichage dans Code scanning, revue des dépendances | gratuit | GitHub Code Security |
| Secret scanning, protection à l'envoi | gratuit | GitHub Secret Protection |
| Attestation de provenance | gratuit | GitHub Enterprise Cloud |

Sans ces licences, les workflows tournent quand même : leurs résultats restent dans les journaux.
