# Procédure complète : du dépôt vide à la release avec SBOM et provenance

Cette procédure part du modèle `ExempleProjet` et va jusqu'à une version livrée : release, SBOM, attestation de provenance.
Elle se suit **dans l'ordre** : chaque étape suppose la précédente faite.

Pour chaque étape, le tableau donne **où cliquer** ou **la commande à taper**, puis **ce que vous devez voir**.
Si vous ne voyez pas ce qui est indiqué, arrêtez-vous et cherchez pourquoi avant de continuer.

Dans les commandes, remplacez :

| Repère | Par | Exemple |
|---|---|---|
| `ORGANISATION` | le nom de l'organisation GitHub | `mon-entreprise` |
| `DEPOT` | le nom du nouveau dépôt | `gestion-presse` |
| `MonProjet` | le nom du projet Visual Studio (lettres, chiffres, `_`, sans espace) | `GestionPresse` |
| `login` | un identifiant GitHub | `jdupont` |

Les commandes se tapent dans **PowerShell** (ou le terminal de Visual Studio), à la racine du dépôt sauf indication contraire.

## Sommaire

| # | Étape | Qui | Combien de fois |
|---|---|---|---|
| 0 | Prérequis | chacun | une fois |
| 1 | Poste du développeur | chacun | une fois par poste |
| 2 | Organisation et équipes | propriétaire de l'organisation | une fois, puis à chaque arrivée |
| 3 | Créer le dépôt à partir du modèle | administrateur | à chaque projet |
| 4 | Adapter le modèle et premier push | administrateur | à chaque projet |
| 5 | Donner l'accès aux équipes | administrateur | à chaque projet |
| 6 | Réglages du dépôt : pull requests et Actions | administrateur | à chaque projet |
| 7 | Labels | administrateur | à chaque projet |
| 8 | Sécurité : Advanced Security et variables | administrateur | à chaque projet |
| 9 | Ruleset : protéger `main` | administrateur | à chaque projet |
| 10 | Première pull request, de l'issue à la fusion | développeurs | à chaque changement |
| 11 | Dependabot et alertes | référent sécurité | chaque lundi |
| 12 | Livrer une version : tag, release, SBOM, provenance | responsables | à chaque livraison |
| 13 | Vérification finale | administrateur | à la fin, puis tous les trois mois |

---

## 0. Prérequis

| Élément | Pourquoi |
|---|---|
| Une **organisation** GitHub, jamais un compte personnel | les équipes, les rulesets et CODEOWNERS en dépendent |
| Offre **Team** au minimum pour un dépôt **privé** | en offre Free, un ruleset sur dépôt privé n'est pas appliqué |
| **Deux comptes** au moins dans chaque équipe de relecteurs | l'auteur d'une pull request ne peut pas l'approuver lui-même |
| Visual Studio 2022 en version 17.14, avec le SDK Windows | compilation MSBuild, `vstest.console`, `signtool` |
| Git pour Windows | |
| GitHub CLI `gh`, connecté : `gh auth login` | toutes les commandes `gh` de cette procédure |
| `actionlint.exe` dans le `PATH` (releases du projet `rhysd/actionlint`) | vérifier un workflow avant de le pousser |

Ce qui est payant sur un dépôt **privé** (gratuit sur un dépôt public) :

| Fonction | Licence nécessaire en privé | Sans la licence |
|---|---|---|
| Revue des dépendances, affichage dans Code scanning | GitHub Code Security | variable `CODE_SECURITY` = `non` (étape 8) |
| Secret scanning, protection à l'envoi | GitHub Secret Protection | Gitleaks dans le pipeline, gratuit, déjà dans le modèle |
| Attestation de provenance | GitHub Enterprise Cloud | variable `ATTESTATION` = `non` (étape 8) |

Dependabot, le graphe des dépendances et tous les workflows du modèle restent gratuits.

---

## 1. Poste du développeur

Une fois par poste.

| # | Commande | Ce que vous devez voir |
|---|---|---|
| 1.1 | `git config --global user.name "Prénom Nom"` | rien |
| 1.2 | `git config --global user.email "ID+login@users.noreply.github.com"` (adresse noreply : GitHub, **Settings**, **Emails**) | rien |
| 1.3 | `git config --global init.defaultBranch main` | rien |
| 1.4 | `git config --global core.editor "notepad"` | rien ; sinon Git ouvre Vim |
| 1.5 | `git config --global fetch.prune true` | rien |
| 1.6 | `git config --global core.quotepath false` | rien ; les accents restent lisibles dans `git status` |
| 1.7 | `git config --global --list` | les valeurs des lignes 1.1 à 1.6 |
| 1.8 | `gh auth login`, puis **GitHub.com**, **HTTPS**, **Login with a web browser** | `Logged in as login` |
| 1.9 | `gh auth status` | `✓ Logged in to github.com account login` |
| 1.10 | `actionlint -version` | un numéro de version |

Sur GitHub, chaque compte : **Settings**, **Password and authentication**, authentification à deux facteurs activée.

---

## 2. Organisation et équipes

Fait par le **propriétaire de l'organisation**. Page de l'organisation, onglet **Settings**.

### 2.1 Réglages de l'organisation

| # | Où cliquer | Réglage | Ce que vous devez voir |
|---|---|---|---|
| 2.1.1 | **Authentication security** | **Require two-factor authentication** : coché | ⚠ les membres sans double authentification sont retirés de l'organisation : prévenez-les avant |
| 2.1.2 | **Member privileges**, **Base permissions** | **Read** | un membre peut lire tous les dépôts, n'écrit que là où son équipe a un accès |
| 2.1.3 | **Member privileges**, **Repository creation** | **Public** décoché si l'entreprise ne publie rien | seuls les dépôts privés peuvent être créés |

Vérification :

```powershell
gh api orgs/ORGANISATION --jq '{default_repository_permission, two_factor_requirement_enabled}'
```

Vous devez voir : `"default_repository_permission":"read"` et `"two_factor_requirement_enabled":true`.

### 2.2 Les deux équipes

| Équipe | Membres | Accès au dépôt (étape 5) | Rôle |
|---|---|---|---|
| `developpeurs` | toute l'équipe de développement | **Write** | proposer, relire le code |
| `responsables` | au moins deux personnes | **Maintain** | relire `.github/`, workflows, `SECURITY.md`, règles de secrets ; poser les tags |

| # | Où cliquer, ou commande | Ce que vous devez voir |
|---|---|---|
| 2.2.1 | Organisation, onglet **Teams**, **New team** : nom `developpeurs`, visibilité **Visible**, **Create team** | la page de l'équipe |
| 2.2.2 | même chose pour `responsables` | la page de l'équipe |
| 2.2.3 | dans chaque équipe : **Add a member**, puis le login | le membre dans la liste |

Équivalent en ligne de commande :

```powershell
gh api -X POST orgs/ORGANISATION/teams -f name=developpeurs -f privacy=closed
gh api -X POST orgs/ORGANISATION/teams -f name=responsables -f privacy=closed
gh api -X PUT orgs/ORGANISATION/teams/developpeurs/memberships/login -f role=member
gh api -X PUT orgs/ORGANISATION/teams/responsables/memberships/login -f role=member
```

Vérification :

```powershell
gh api orgs/ORGANISATION/teams --jq '.[] | "\(.slug) \(.privacy)"'
gh api orgs/ORGANISATION/teams/responsables/members --jq '.[].login'
```

Vous devez voir : `developpeurs closed` et `responsables closed` (`closed` = **Visible**), puis au moins deux logins.
Une équipe **secrète** ne fonctionne pas dans CODEOWNERS.

---

## 3. Créer le dépôt à partir du modèle

### 3.1 Une fois pour toutes : publier le modèle

Fait par le formateur ou le propriétaire de l'organisation : le modèle `ExempleProjet` est un dépôt de l'organisation,
marqué comme modèle.

```powershell
gh repo edit ORGANISATION/ExempleProjet --template
```

Vous devez voir, sur la page du dépôt : la mention **Template** sous son nom et le bouton vert **Use this template**.

### 3.2 Créer le nouveau dépôt

| # | Où cliquer, ou commande | Ce que vous devez voir |
|---|---|---|
| 3.2.1 | page de `ExempleProjet`, **Use this template**, **Create a new repository** | le formulaire de création |
| 3.2.2 | **Owner** : `ORGANISATION` ; **Repository name** : `DEPOT` ; **Private** ; **Include all branches** décoché ; **Create repository** | le nouveau dépôt, avec tous les fichiers du modèle et un seul commit |

Équivalent en ligne de commande :

```powershell
gh repo create ORGANISATION/DEPOT --private --template ORGANISATION/ExempleProjet
```

### 3.3 Cloner dans un chemin **court**

Windows limite les chemins à 260 caractères : les projets de tests ont des chemins longs. Clonez dans `C:\dev`.

```powershell
git clone https://github.com/ORGANISATION/DEPOT.git C:\dev\DEPOT
cd C:\dev\DEPOT
git log --oneline
```

Vous devez voir : un seul commit, `Initial commit`.

---

## 4. Adapter le modèle et premier push

C'est le **seul** push direct sur `main` : le ruleset (étape 9) l'interdira ensuite. Tout ce qui suit se fait sur le poste,
dans `C:\dev\DEPOT`.

### 4.1 Renommer le projet

```powershell
powershell -ExecutionPolicy Bypass -File outils\renommer-projet.ps1 -Nouveau MonProjet
```

Vous devez voir : `Fichiers modifiés : 16 ; éléments renommés : 5 ; GUID renouvelés : 4`.

Le script renomme les dossiers et fichiers, remplace `ExempleProjet` partout (solution, projets, espaces de noms,
workflows, documentation), donne de nouveaux identifiants (GUID) aux projets, et conserve l'encodage de chaque fichier.

Vérification :

```powershell
git status --short
Get-ChildItem -Recurse -File -Force -Exclude *.ps1, procedure-complete.md | Where-Object FullName -notmatch '\\\.git\\' | Select-String -SimpleMatch ExempleProjet -List
```

Vous devez voir : des fichiers supprimés, ajoutés et modifiés ; la seconde commande n'affiche rien.

### 4.2 Remplacer les repères

| # | Fichier | À faire | Ce que vous devez voir |
|---|---|---|---|
| 4.2.1 | `.github/CODEOWNERS` | remplacer `ORGANISATION` (Ctrl+H dans Visual Studio, **Remplacer tout**) par le nom de l'organisation | `@mon-entreprise/developpeurs` |
| 4.2.2 | `SECURITY.md` | remplacer chaque valeur entre `< >` : versions, adresse, délais. **Adresse et délais validés par la direction** | plus aucun `<` hors commentaires |
| 4.2.3 | `docs/charte-git.md` | remplacer chaque valeur entre `< >` ; relire chaque règle en équipe | plus aucun `<` hors commentaires |
| 4.2.4 | `README.md` | décrire le projet ; compléter le tableau des DLL hors NuGet | le nom et le rôle du projet en tête |
| 4.2.5 | `.github/dependabot.yml` | sous `directories`, un dossier par `packages.config` du projet. Décommenter `- "/MonProjet"` si l'application a des paquets NuGet | `git ls-files "*packages.config"` liste exactement ces dossiers |
| 4.2.6 | `.github/outils/composants-hors-nuget.json` | une entrée par DLL de fournisseur copiée sans NuGet (voir le mode d'emploi dans le fichier) | `"composants": []` s'il n'y en a aucune |

Recherche de ce qui reste à remplacer :

```powershell
Select-String -Path .github\CODEOWNERS, SECURITY.md, docs\charte-git.md -Pattern "ORGANISATION|<[a-zé]"
```

Vous devez voir : rien.

### 4.3 Vérifier avant de pousser

| # | Commande | Ce que vous devez voir |
|---|---|---|
| 4.3.1 | `actionlint .github\workflows\*.yml` | rien : aucune erreur |
| 4.3.2 | `msbuild MonProjet.sln -t:restore -p:RestorePackagesConfig=true` (invite de commandes développeur de Visual Studio) | `Package '…' ajouté au dossier` |
| 4.3.3 | `msbuild MonProjet.sln -p:Configuration=Release` | `0 Erreur(s)` |
| 4.3.4 | `vstest.console tests\MonProjet.Tests\bin\Release\MonProjet.Tests.dll` | `Réussi(s) : 2` |
| 4.3.5 | `git status --short` | aucun fichier sous `bin\`, `obj\` ou `packages\` |

Dans Visual Studio, pour vérifier l'indentation d'un `.yml` : **Édition**, **Avancé**, **Afficher les espaces blancs**
(Ctrl+R, Ctrl+W). Un point par espace, **aucune flèche** : une flèche est une tabulation, refusée par YAML.

### 4.4 Premier commit et push

```powershell
git add -A
git commit -m "chore: projet MonProjet créé à partir du modèle"
git push
```

Vous devez voir : `main -> main`. Sur GitHub, onglet **Actions** : les workflows **Build**, **Tests**,
**Détection de secrets** et **Analyse de code** démarrent. Attendez qu'ils soient **verts** (5 minutes environ).

Le workflow **Analyse de code** sera rouge sur un dépôt privé sans licence tant que l'étape 8.3 n'est pas faite : c'est normal.

---

## 5. Donner l'accès aux équipes

Un nouveau dépôt ne donne rien aux équipes. Sans cette étape, un développeur ne peut ni pousser, ni faire compter son approbation,
et CODEOWNERS ne fonctionne pas.

| # | Où cliquer | Ce que vous devez voir |
|---|---|---|
| 5.1 | dépôt, **Settings**, **Collaborators and teams**, **Add teams**, `developpeurs`, rôle **Write** | `developpeurs` avec **Write** |
| 5.2 | même chose pour `responsables`, rôle **Maintain** | `responsables` avec **Maintain** |

Équivalent en ligne de commande :

```powershell
gh api -X PUT orgs/ORGANISATION/teams/developpeurs/repos/ORGANISATION/DEPOT -f permission=push
gh api -X PUT orgs/ORGANISATION/teams/responsables/repos/ORGANISATION/DEPOT -f permission=maintain
```

Vérification :

```powershell
gh api repos/ORGANISATION/DEPOT/teams --jq '.[] | "\(.slug) \(.permission)"'
gh api repos/ORGANISATION/DEPOT/codeowners/errors
```

Vous devez voir : `developpeurs push` et `responsables maintain` (`push` = **Write**), puis `{"errors":[]}`.
Dans le dépôt, ouvrez `.github/CODEOWNERS` : aucun bandeau d'erreur.

---

## 6. Réglages du dépôt : pull requests et Actions

### 6.1 Pull requests

Dépôt, **Settings**, **General**, rubrique **Pull Requests** :

| Réglage | Valeur | Pourquoi |
|---|---|---|
| **Allow merge commits** | ✅ coché | seul mode autorisé : le commit de fusion porte le numéro de la PR |
| **Allow squash merging** | ⬜ décoché | |
| **Allow rebase merging** | ⬜ décoché | |
| **Always suggest updating pull request branches** | ✅ coché | bouton **Update branch** sur une PR en retard |
| **Allow auto-merge** | ⬜ décoché | une fusion se décide, elle ne part pas seule |
| **Automatically delete head branches** | ✅ coché | les branches fusionnées disparaissent |

Équivalent en ligne de commande :

```powershell
gh repo edit ORGANISATION/DEPOT --enable-merge-commit --enable-squash-merge=false --enable-rebase-merge=false --allow-update-branch --enable-auto-merge=false --delete-branch-on-merge
```

Vérification :

```powershell
gh api repos/ORGANISATION/DEPOT --jq '{allow_merge_commit, allow_squash_merge, allow_rebase_merge, allow_update_branch, allow_auto_merge, delete_branch_on_merge}'
```

Vous devez voir : `true`, `false`, `false`, `true`, `false`, `true`, dans cet ordre.

### 6.2 Actions

Dépôt, **Settings**, **Actions**, **General**, rubrique **Workflow permissions** :

| Réglage | Valeur | Pourquoi |
|---|---|---|
| **Read repository contents and packages permissions** | ✅ sélectionné | un workflow ne peut rien modifier, sauf s'il le demande lui-même (`release.yml` le fait pour la release) |
| **Allow GitHub Actions to create and approve pull requests** | ⬜ décoché | un workflow ne doit jamais approuver une PR |

Équivalent en ligne de commande :

```powershell
gh api -X PUT repos/ORGANISATION/DEPOT/actions/permissions/workflow -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
```

Vérification :

```powershell
gh api repos/ORGANISATION/DEPOT/actions/permissions/workflow
```

Vous devez voir : `{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}`.

---

## 7. Labels

Les labels `dependances` et `ci` doivent exister **avant** que Dependabot ouvre ses pull requests.
Les labels par défaut de GitHub sont remplacés par ceux de la charte.

| # | Commande | Ce que vous devez voir |
|---|---|---|
| 7.1 | supprimer les labels par défaut :<br>`"bug","duplicate","enhancement","good first issue","help wanted","invalid","question","wontfix" \| ForEach-Object { gh label delete $_ --yes -R ORGANISATION/DEPOT }` | `✓ Label "bug" deleted…` pour chacun |
| 7.2 | labels de nature, de priorité et d'outillage : les commandes ci-dessous | `✓ Label "securite" created…` pour chacun |
| 7.3 | `gh label list -R ORGANISATION/DEPOT` | les dix labels de la charte, et aucun autre |

```powershell
$d = "ORGANISATION/DEPOT"
gh label create securite      --color B60205 --description "Faille ou correctif de sécurité" --force -R $d
gh label create anomalie      --color 1D76DB --description "Dysfonctionnement" --force -R $d
gh label create evolution     --color 1D76DB --description "Nouvelle fonctionnalité ou amélioration" --force -R $d
gh label create documentation --color 1D76DB --description "Documentation seule" --force -R $d
gh label create p1-bloquant   --color FBCA04 --description "Bloquant en production" --force -R $d
gh label create p2-important  --color FBCA04 --description "Important" --force -R $d
gh label create p3-normal     --color FBCA04 --description "Normal" --force -R $d
gh label create dependances   --color 5319E7 --description "Mise à jour de paquet ou d'action" --force -R $d
gh label create ci            --color 5319E7 --description "Intégration continue" --force -R $d
```

Une couleur par famille : nature en bleu (sécurité en rouge, pour la voir de loin), priorité en jaune, outillage en violet.

---

## 8. Sécurité : Advanced Security et variables

### 8.1 Advanced Security

Dépôt, **Settings**, **Advanced Security**. Cliquer sur **Enable** en face de chaque ligne :

| Réglage | Dépôt public | Dépôt privé | Ce qu'il fait |
|---|---|---|---|
| **Dependency graph** | ✅ | ✅ | liste les paquets à partir des `packages.config` |
| **Automatic dependency submission** | ⬜ inutile | ⬜ inutile | utile seulement pour les projets au format SDK ; `packages.config` liste déjà tout |
| **Dependabot alerts** | ✅ | ✅ | alerte sur une faille connue dans un paquet |
| **Dependabot malware alerts** | ✅ | ✅ | alerte sur un paquet malveillant ; désactivé par défaut |
| **Dependabot security updates** | ✅ | ✅ | ouvre une PR de correction pour une faille |
| **Grouped security updates** | ✅ | ✅ | une seule PR pour plusieurs corrections |
| **Dependabot version updates** | réglé par `.github/dependabot.yml` | idem | rien à cliquer |
| **Code scanning**, **CodeQL analysis** | ⬜ **Set up** non cliqué | ⬜ | CodeQL n'analyse pas le VB ; le modèle utilise Roslyn et DevSkim |
| **Secret Protection** | ✅ | ✅ si licence | détecte les secrets à marqueur de fournisseur |
| **Push protection** (sous Secret Protection) | ✅ | ✅ si licence | refuse un push qui contient un secret |
| **Private vulnerability reporting** | ✅ | n'existe pas | bouton **Report a vulnerability** pour les chercheurs |

Vous devez voir : chaque ligne activée affiche un bouton **Disable**.

Équivalent en ligne de commande, pour ce qui a une commande (les alertes malware se règlent seulement dans l'interface) :

```powershell
gh api -X PUT repos/ORGANISATION/DEPOT/vulnerability-alerts
gh api -X PUT repos/ORGANISATION/DEPOT/automated-security-fixes
gh api -X PUT repos/ORGANISATION/DEPOT/private-vulnerability-reporting        # dépôt public seulement
```

Vérification :

```powershell
gh api repos/ORGANISATION/DEPOT --jq '.security_and_analysis'
```

Vous devez voir : `"dependabot_security_updates":{"status":"enabled"}`, et, si activés,
`"secret_scanning":{"status":"enabled"}` et `"secret_scanning_push_protection":{"status":"enabled"}`.

### 8.2 Organisation : pour que les prochains dépôts en héritent

Organisation, **Settings**, **Advanced Security**, **Configurations** : une configuration qui reprend les choix du tableau 8.1,
appliquée par défaut aux nouveaux dépôts. Sans elle, chaque nouveau dépôt repart de zéro.

### 8.3 Variables de dépôt, si une licence manque (dépôt privé)

Dépôt, **Settings**, **Secrets and variables**, **Actions**, onglet **Variables**, **New repository variable** :

| Variable | Valeur | Quand | Effet |
|---|---|---|---|
| `CODE_SECURITY` | `non` | dépôt privé sans GitHub Code Security | revue des dépendances sautée ; résultats d'analyse gardés en artefact au lieu de Code scanning |
| `ATTESTATION` | `non` | dépôt privé sans GitHub Enterprise Cloud | release sans attestation de provenance |

Équivalent en ligne de commande :

```powershell
gh variable set CODE_SECURITY --body non -R ORGANISATION/DEPOT
gh variable set ATTESTATION --body non -R ORGANISATION/DEPOT
gh variable list -R ORGANISATION/DEPOT
```

Vous devez voir : les deux variables avec la valeur `non`. Sur un dépôt public, ne créez aucune variable.

---

## 9. Ruleset : protéger `main`

Le ruleset rend les règles **obligatoires**, propriétaire compris : pull request, revue, contrôles verts.

### 9.1 Créer le ruleset

Le plus sûr : importer le fichier fourni, `docs/ruleset-protection-main.json`.

| # | Où cliquer | Ce que vous devez voir |
|---|---|---|
| 9.1.1 | dépôt, **Settings**, **Rules**, **Rulesets**, **New ruleset**, **Import a ruleset** | la fenêtre de choix de fichier |
| 9.1.2 | choisir `docs\ruleset-protection-main.json` dans le clone | le formulaire du ruleset, déjà rempli |
| 9.1.3 | relire avec le tableau 9.2, puis **Create** | le ruleset `protection-main`, **Active** |

Équivalent en ligne de commande :

```powershell
gh api -X POST repos/ORGANISATION/DEPOT/rulesets --input docs\ruleset-protection-main.json
```

### 9.2 Ce que contient le ruleset

| Réglage | Valeur |
|---|---|
| **Ruleset Name** | `protection-main` |
| **Enforcement status** | **Active** |
| **Bypass list** | **vide** : personne, propriétaire compris |
| **Target branches** | **Include default branch** et **Include by pattern** `release/**` |
| **Restrict creations** | ⬜ |
| **Restrict updates** | ⬜ |
| **Restrict deletions** | ✅ |
| **Require linear history** | ⬜ incompatible avec les commits de fusion |
| **Require deployments to succeed** | ⬜ |
| **Require signed commits** | ⬜ (sauf décision de la charte) |
| **Require a pull request before merging** | ✅ |
| ↳ **Required approvals** | `1` |
| ↳ **Dismiss stale pull request approvals when new commits are pushed** | ✅ |
| ↳ **Require review from Code Owners** | ✅ sans lui, CODEOWNERS ne bloque rien |
| ↳ **Require approval of the most recent reviewable push** | ⬜ |
| ↳ **Require conversation resolution before merging** | ✅ |
| ↳ **Allowed merge methods** | **Merge** seul |
| **Require status checks to pass** | ✅ |
| ↳ **Require branches to be up to date before merging** | ⬜ |
| ↳ **Do not require status checks on creation** | ⬜ |
| ↳ **Status checks** | `build`, `tests`, `issue-liee`, `titre-pr`, `detection-secrets` |
| **Block force pushes** | ✅ |
| **Require code scanning results** | ⬜ au départ ; à activer quand les alertes existantes sont triées, et si la licence le permet |

Sur un dépôt **public**, ou **privé avec Code Security** : ajoutez aussi le contrôle `revue-dependances`
(**Add checks**, taper `revue-dependances`). Sans licence, ne l'ajoutez pas : le job est sauté et ne serait jamais vert.

Un contrôle requis porte **le nom du job** (`build`), pas celui du workflow (`Build`). Renommer un job casse la règle.

### 9.3 Vérifier que `main` est protégée

```powershell
git commit --allow-empty -m "test: push direct sur main"
git push
```

Vous devez voir : le push **refusé**, `GH013: Repository rule violations found for refs/heads/main`.

Puis annuler ce commit local :

```powershell
git reset --hard origin/main
```

Vous devez voir : `HEAD is now at …`, le dernier commit poussé à l'étape 4.

---

## 10. Première pull request, de l'issue à la fusion

Le circuit de **tout** changement. Exemple : compléter le README.

| # | Où cliquer, ou commande | Ce que vous devez voir |
|---|---|---|
| 10.1 | **Issues**, **New issue**, modèle **Évolution** ; titre : « README : décrire l'installation » ; label `documentation` ; **Create** | l'issue, avec son numéro, par exemple **#1**. Lisez le numéro sur GitHub : ne le devinez jamais |
| 10.2 | `git switch main`<br>`git pull` | `Already up to date.` ou la liste des fichiers reçus |
| 10.3 | `git switch -c docs/1-readme-installation` | `Switched to a new branch 'docs/1-readme-installation'` |
| 10.4 | modifier `README.md` dans Visual Studio, enregistrer | |
| 10.5 | `git add README.md`<br>`git commit -m "docs(readme): décrit l'installation" -m "Refs #1"` | `1 file changed` |
| 10.6 | `git push -u origin docs/1-readme-installation` | `branch 'docs/1-readme-installation' set up to track…` |
| 10.7 | sur GitHub, bandeau jaune **Compare & pull request** | le formulaire, pré-rempli par le modèle de PR |
| 10.8 | titre : `docs(readme): décrit l'installation` ; sous **Issue liée** : `Closes #1` ; cocher la nature **Documentation** ; label `documentation` ; **Create pull request** | la PR ouverte ; les relecteurs `developpeurs` demandés d'office |
| 10.9 | onglet **Checks** de la PR, attendre | `build`, `tests`, `issue-liee`, `titre-pr`, `detection-secrets` **verts** ; le bouton de fusion reste gris : il manque une approbation |
| 10.10 | **un autre membre** : onglet **Files changed**, **Review changes**, **Approve**, **Submit review** | « Changes approved » |
| 10.11 | l'auteur ou un responsable : **Merge pull request**, **Confirm merge** | « Pull request successfully merged and closed » ; l'issue #1 passe à **Closed** ; la branche est supprimée |
| 10.12 | `git switch main`<br>`git pull` | le commit de fusion « Merge pull request #2 from … » |
| 10.13 | `git branch -d docs/1-readme-installation` | `Deleted branch docs/1-readme-installation` |

Ce que les contrôles refusent, et comment corriger :

| Contrôle rouge | Cause | Correction |
|---|---|---|
| `issue-liee` | pas de `Closes #N`, `Fixes #N` ou `Refs #N` dans la description | modifier la description de la PR : le contrôle se relance seul |
| `titre-pr` | titre hors format, par exemple « Docs/1 readme » | modifier le titre : `type(portée): description` |
| `build` ou `tests` | le code ne compile pas, ou un test échoue | **Details**, lire l'étape en rouge, corriger, `git commit`, `git push` |
| `detection-secrets` | un secret dans le code ou l'historique de la branche | **révoquer d'abord le secret**, puis le retirer du code ; voir `.gitleaksignore` pour une trouvaille historique |

Une PR qui modifie `.github/`, `SECURITY.md` ou les règles de secrets demande aussi l'approbation d'un membre de `responsables`.

---

## 11. Dependabot et alertes

### 11.1 Vérifier que Dependabot tourne

| # | Où cliquer | Ce que vous devez voir |
|---|---|---|
| 11.1.1 | **Insights**, **Dependency graph**, onglet **Dependencies** | les paquets des `packages.config` |
| 11.1.2 | **Insights**, **Dependency graph**, onglet **Dependabot** | une ligne **nuget** par dossier listé, une ligne **github-actions**, chacune avec **Last checked** et aucune erreur |
| 11.1.3 | sur une ligne, **Check for updates** | la vérification relancée ; une PR de Dependabot apparaît si une mise à jour existe |

### 11.2 Traiter les pull requests de Dependabot, chaque lundi

| # | Où cliquer, ou commande | Ce que vous devez voir |
|---|---|---|
| 11.2.1 | **Pull requests**, filtre : `is:open author:app/dependabot` | une PR groupée pour les mineures, une PR par montée majeure |
| 11.2.2 | **Issues**, **New issue** : « Qualification des mises à jour du AAAA-MM-JJ » ; pour chaque PR : faille ou simple version ? montée majeure ? le livrable fonctionne-t-il encore ? ; décision : fusionner, refuser, reporter avec une date | l'issue, avec une décision par PR |
| 11.2.3 | PR acceptée : contrôles verts, approbation, **Merge pull request** | PR fusionnée |
| 11.2.4 | PR refusée : commentaire `Refusée : voir #N.`, puis, sur une ligne seule, `@dependabot ignore this major version` | Dependabot ferme la PR et ne repropose plus cette version majeure |
| 11.2.5 | décision durable : bloc `ignore` dans `.github/dependabot.yml`, par une PR qui cite l'issue | la montée majeure n'est plus proposée |

Un build vert ne prouve pas que le livrable fonctionne : le job `build` vérifie aussi que chaque DLL livrée se charge,
mais testez l'exécutable avant de livrer une montée majeure.

### 11.3 Alertes de sécurité

| # | Où cliquer | Ce que vous devez voir |
|---|---|---|
| 11.3.1 | onglet **Security and quality**, **Dependabot** | les alertes ouvertes, ou aucune |
| 11.3.2 | **Code scanning** (si licence), menu **Tool** | les alertes des outils `Microsoft (R) Visual Basic Compiler` et `devskim` |
| 11.3.3 | alerte à corriger : issue `securite`, branche `fix/…`, PR | l'alerte passe à **Fixed** après la fusion |
| 11.3.4 | faux positif : **Dismiss alert**, **False positive**, motif écrit | l'alerte fermée, avec le motif et son auteur |
| 11.3.5 | sans licence Code Security : **Actions**, workflow **Analyse de code**, artefacts `sarif-roslyn` et `sarif-devskim` | les fichiers SARIF, à ouvrir dans Visual Studio (extension **Microsoft SARIF Viewer**) |

---

## 12. Livrer une version : tag, release, SBOM, provenance

Une version livrée = **un tag** `vMAJEUR.MINEUR.CORRECTIF`. Le workflow **Release** fait le reste :
il aligne la version de l'exécutable sur le tag, compile, assemble le livrable, produit le SBOM,
génère l'attestation de provenance et publie la release. Binaire, SBOM et attestation partent du même tag.

### 12.1 Préparer la version

| # | Où cliquer, ou commande | Ce que vous devez voir |
|---|---|---|
| 12.1.1 | issue « Version 1.0.0 », branche `docs/N-version-1-0-0` ; dans `CHANGELOG.md`, renommer `[Non publié]` en `[1.0.0] - AAAA-MM-JJ` et rouvrir une section `[Non publié]` vide au-dessus | |
| 12.1.2 | commit `docs(changelog): version 1.0.0`, push, PR, revue, fusion (étape 10) | la PR fusionnée |
| 12.1.3 | DLL de fournisseurs : vérifier `.github/outils/composants-hors-nuget.json` | une entrée par DLL livrée hors NuGet |

### 12.2 Poser le tag

Fait par un membre de `responsables`, sur `main` à jour :

| # | Commande | Ce que vous devez voir |
|---|---|---|
| 12.2.1 | `git switch main`<br>`git pull` | le commit de fusion de 12.1.2 |
| 12.2.2 | `git tag -a v1.0.0 -m "Version 1.0.0"` | rien |
| 12.2.3 | `git push origin v1.0.0` | `* [new tag] v1.0.0 -> v1.0.0` |
| 12.2.4 | `gh run list --workflow release.yml -R ORGANISATION/DEPOT` | une exécution sur `v1.0.0`, en cours |
| 12.2.5 | `gh run watch -R ORGANISATION/DEPOT` (choisir l'exécution) | trois jobs : `binaire` et `sbom`, puis `publication`, tous ✓ |

Un tag mal formé (`v1.0`, `1.0.0`) fait échouer le job `binaire` : « Tag attendu : vMAJEUR.MINEUR.CORRECTIF ».
Supprimez-le (`git push origin --delete v1.0` puis `git tag -d v1.0`) et posez le bon.

### 12.3 Vérifier la release

| # | Commande | Ce que vous devez voir |
|---|---|---|
| 12.3.1 | `gh release view v1.0.0 -R ORGANISATION/DEPOT` | titre `MonProjet 1.0.0`, auteur `github-actions`, deux fichiers : `MonProjet-1.0.0.zip` et `MonProjet-1.0.0.cdx.json` ; pas de mention **Pre-release** |
| 12.3.2 | `gh release download v1.0.0 -D C:\livraison\v1.0.0 -R ORGANISATION/DEPOT` | les deux fichiers dans `C:\livraison\v1.0.0` |
| 12.3.3 | ouvrir `MonProjet-1.0.0.cdx.json` dans Visual Studio, chercher `"metadata"` | `"name": "MonProjet"`, `"version": "1.0.0"` : le SBOM correspond au tag |
| 12.3.4 | chercher `"components"` | un bloc par paquet NuGet livré, avec `purl` et licence, puis les DLL hors NuGet avec leur empreinte SHA-256 |
| 12.3.5 | `Expand-Archive C:\livraison\v1.0.0\MonProjet-1.0.0.zip C:\livraison\v1.0.0\contenu`<br>`(Get-Item C:\livraison\v1.0.0\contenu\MonProjet.exe).VersionInfo.FileVersion` | `1.0.0.0` : la version de l'exécutable est celle du tag |

### 12.4 Vérifier la provenance

Seulement si l'attestation est produite (dépôt public, ou privé avec GitHub Enterprise Cloud) :

| # | Commande | Ce que vous devez voir |
|---|---|---|
| 12.4.1 | `gh attestation verify C:\livraison\v1.0.0\MonProjet-1.0.0.zip --owner ORGANISATION`<br>`$LASTEXITCODE` | `0` : le fichier vient bien du workflow, depuis ce dépôt et ce tag. PowerShell peut n'afficher rien d'autre |
| 12.4.2 | `gh attestation verify C:\livraison\v1.0.0\contenu\MonProjet.exe --owner ORGANISATION`<br>`$LASTEXITCODE` | `0` |

Un fichier modifié d'un seul octet, ou compilé sur un poste, est **refusé** : aucune attestation n'existe pour son empreinte.

### 12.5 Signer l'exécutable

Le modèle ne signe pas : la signature demande un certificat de l'entreprise (OV, EV ou signature cloud), à choisir et à acheter.
En attendant, à la main, sur une **copie** du livrable, avec `signtool` du SDK Windows :

```powershell
signtool sign /fd SHA256 /sha1 <empreinte du certificat> /tr http://timestamp.digicert.com /td SHA256 MonProjet.exe
signtool verify /pa /v MonProjet.exe
```

Vous devez voir : `Successfully signed`, puis l'horodatage dans le résultat de `verify`.
Signez l'`.exe` et les `.dll` écrites par l'équipe, jamais les DLL de fournisseurs. Une fois signé, l'exécutable
n'a plus l'empreinte attestée en 12.4 : à terme, la signature se fait dans le workflow, **avant** l'attestation.

### 12.6 Corriger une version déjà livrée

```powershell
git switch -c release/1.0 v1.0.0
git push -u origin release/1.0
```

Puis, pour chaque correctif : branche depuis `release/1.0`, `git cherry-pick -x <sha du correctif sur main>`, PR vers `release/1.0`,
revue, fusion, tag `v1.0.1` sur `release/1.0`. Le ruleset protège aussi `release/**`.

---

## 13. Vérification finale

| # | Vérification | Ce que vous devez voir |
|---|---|---|
| 13.1 | un membre de `developpeurs` clone le dépôt et pousse une branche | le push accepté |
| 13.2 | `git push` direct sur `main` | refusé, `GH013`, propriétaire compris |
| 13.3 | une PR sans approbation | bouton de fusion gris |
| 13.4 | une PR qui casse un test | `tests` rouge, fusion impossible |
| 13.5 | une PR qui modifie `.github/` | revue de `responsables` demandée d'office |
| 13.6 | une PR sans `Closes #N` | `issue-liee` rouge |
| 13.7 | **Insights**, **Dependency graph**, onglet **Dependabot** | aucune erreur |
| 13.8 | **Security and quality** | chaque alerte corrigée, ou fermée avec un motif |
| 13.9 | dernière release | binaire du pipeline, SBOM, attestation vérifiée, entrée de changelog |
| 13.10 | `CHECKLIST.md` | chaque case cochée dans la PR qui l'a réalisée |

À revérifier **tous les trois mois** : branches longues qui reviennent, revues approuvées en deux minutes,
alertes non triées, contournements d'urgence devenus l'usage, et surtout **le nouveau dépôt créé sans cette procédure**.

---

## En cas de problème

| Ce que vous voyez | Pourquoi | Quoi faire |
|---|---|---|
| « Invalid workflow file » dans **Actions** | indentation cassée, ou tabulation, souvent après un copier-coller depuis un PDF | `actionlint` ; **Afficher les espaces blancs** ; recopier le fichier du modèle |
| une PR bloquée sur « Expected — Waiting for status to be reported » | un contrôle requis n'est produit par aucun workflow (nom de job changé, licence absente) | corriger le nom dans le ruleset, ou retirer le contrôle |
| `GH013` sur un push vers une branche de travail | la branche s'appelle `main` ou `release/…` | `git switch -c type/N-libelle`, puis pousser cette branche |
| `Permission denied` au push | l'équipe n'a pas accès au dépôt | étape 5 |
| bandeau « This CODEOWNERS file contains errors » | équipe inexistante, secrète, ou sans accès Write | étapes 2.2 et 5 |
| les relecteurs ne sont pas demandés d'office | CODEOWNERS pas encore sur `main`, ou erreur ci-dessus | `gh api repos/ORGANISATION/DEPOT/codeowners/errors` |
| `Found 0 packages` ou erreur MSBuild sur un chemin | chemin de plus de 260 caractères | cloner dans `C:\dev` |
| erreur sur un dossier dans l'onglet **Dependabot** | dossier sans `packages.config` dans `dependabot.yml` | corriger `directories` |
| **Analyse de code** rouge sur « upload-sarif » | dépôt privé sans Code Security | variable `CODE_SECURITY` = `non` (étape 8.3) |
| job `binaire` rouge à « Générer l'attestation de provenance » | dépôt privé sans Enterprise Cloud | variable `ATTESTATION` = `non` (étape 8.3) |
| `detection-secrets` rouge : « invalid character at start of key » | `.gitleaks.toml` enregistré avec BOM | le réenregistrer en UTF-8 **sans** BOM |
