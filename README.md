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
| `CHECKLIST.md` | la mise en place du dépôt, case par case |
| `docs/procedure-complete.md` | **la procédure complète**, commande par commande : du dépôt vide à la release avec SBOM et provenance |
| `docs/ruleset-protection-main.json` | le ruleset de `main`, à importer dans GitHub |
| `outils/renommer-projet.ps1` | renomme le modèle pour un nouveau projet |

## Réutiliser le modèle pour un nouveau projet

Suivre `docs/procedure-complete.md`. En résumé :

1. **Créer le dépôt** à partir du modèle (**Use this template**), puis le cloner dans un chemin court (`C:\dev\…`).
2. **Renommer** le projet : `powershell -ExecutionPolicy Bypass -File outils\renommer-projet.ps1 -Nouveau MonProjet`.
   Le script met aussi à jour les lignes `env:` en tête des workflows, seul endroit où ils citent le projet.
3. **Remplacer les repères** : `ORGANISATION` dans `.github/CODEOWNERS`, les valeurs entre `< >`
   dans `SECURITY.md` et `docs/charte-git.md`.
4. **Lister les dossiers** qui contiennent un `packages.config` dans `.github/dependabot.yml`.
5. **Régler le dépôt sur GitHub** : équipes, pull requests, labels, sécurité, ruleset.
6. **Cocher `CHECKLIST.md`** au fil des pull requests.

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

Sans ces licences, créer les variables de dépôt `CODE_SECURITY` = `non` et `ATTESTATION` = `non`
(**Settings**, **Secrets and variables**, **Actions**, **Variables**) : les workflows restent verts,
les résultats d'analyse sont gardés en artefact, et la release part sans attestation.
