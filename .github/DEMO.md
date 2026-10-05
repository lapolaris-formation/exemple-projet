# WinVOIE – projet jumeau pour tester la sécurité GitHub

Projet **fictif** (entreprise FERRODEMO) qui reproduit la configuration technique d'une application
industrielle VB.NET WinForms. Il ne contient **aucun code client** : seulement le même format de projet,
les mêmes packages et versions, le même style de code et les mêmes types d'erreurs.

| Élément | Valeur |
|---|---|
| Framework | .NET Framework 4.8, WinForms, VB.NET (`MyType=WindowsForms`) |
| Format projet | ancien `.vbproj` (ToolsVersion 14) + `packages.config` |
| Packages | 13 identiques à l'original (MathNet 5.0.0, Newtonsoft 13.0.4, PDFsharp 6.2.4…) |
| DLL locales | `WinVOIE\dll\TwinCAT.Ads.dll` et `Fde.Vmp60.Network.dll` = **DLL factices** (même API, aucune logique) |
| Solution | VS 2022 + projet Setup `.vdproj` |

---

## 1. Avant de pousser : visibilité du dépôt

| Fonction | Dépôt public | Dépôt privé (compte perso / org sans licence) | Dépôt privé avec licences GitHub |
|---|---|---|---|
| Dependency graph, Dependabot alerts, Dependabot security/version updates | ✅ | ✅ | ✅ |
| Code scanning (upload SARIF) | ✅ | ❌ | ✅ **GitHub Code Security** |
| Dependency review (action PR) | ✅ | ❌ | ✅ **GitHub Code Security** |
| Secret scanning + push protection | ✅ | ❌ | ✅ **GitHub Secret Protection** |

> Pour l'organisation privée du client : vérifier **avant la démo** qu'ils ont (ou activent en essai)
> *GitHub Code Security* et *GitHub Secret Protection*, sinon seuls Dependabot et le dependency graph marcheront.

## 2. Réglages à activer (Settings > Advanced Security / Code security)

- Dependency graph
- Dependabot alerts + Dependabot security updates
- Secret Protection + Push protection
- Code scanning : **ne pas** utiliser "CodeQL default setup" pour le code (voir §3), les workflows de `.github/workflows` envoient le SARIF

### Modèles d'issue et de PR (repris du cours, jour 2)
- `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/anomalie.md` et `evolution.md`.
- Créer les labels **`anomalie`** et **`evolution`** avant (sinon les issues n'ont pas de label).
- Lus **uniquement sur `main`** : la PR qui les installe a un formulaire vide, les suivantes sont pré-remplies.
- Pas de modèle « sécurité » : une vulnérabilité passe par le canal privé de `SECURITY.md`.

### CODEOWNERS (organisation `lapolaris-formation`)
- Équipes **`developpeurs`** et **`responsables`** : elles doivent exister, être visibles et avoir l'accès **Write** au dépôt.
- Lu sur `main` uniquement ; ne bloque rien sans « Require review from Code Owners » dans le ruleset.
- Vérification : `gh api repos/lapolaris-formation/<depot>/codeowners/errors` → `{"errors":[]}`.

## 3. Résultats attendus (vérifiés en local le 01/10/2026)

### Workflows et contrôles à exiger dans le ruleset

| Workflow | Job (= contrôle requis) | Rôle |
|---|---|---|
| `build.yml` | `build` | compile la solution, **vérifie que chaque assembly livré se charge** (redirections, DLL manquantes), binaires en artefact |
| `tests.yml` | `tests` | compile, lance les tests xUnit, `.trx` en artefact |
| `dependency-review.yml` | `revue-dependances` | bloque une PR qui ajoute un paquet vulnérable (licence en privé) |
| `secrets.yml` | `detection-secrets` | Gitleaks sur tout l'historique, règles maison, trouvailles acquittées tracées |
| `verification-pr.yml` | `issue-liee` | refuse une PR dont la description ne référence aucune issue (Dependabot exempté) |
| `code-scanning.yml` | `roslyn`, `devskim` | signalement seulement (phase 2), **pas** en contrôle requis |

Workflows séparés : plus lisibles et exigeables un par un, au prix d'une compilation en double (`build` et `tests`).

### Restauration des paquets
`msbuild WinVOIE.sln -t:restore -p:RestorePackagesConfig=true` : MSBuild restaure `packages.config` lui-même,
sans `nuget.exe` ni action `setup-nuget`, et NuGet Audit s'exécute (avertissements `NU190x` dans le journal).
Vérifié en local sur un dossier `packages` vide : 24 paquets restaurés (13 application + 11 tests).

### Build (`build.yml`)
- ✅ Compile avec le MSBuild de Visual Studio, warning **MSB4078** sur `Setup.vdproj` (non supporté).
- ❌ `dotnet build` **échoue** (MSB3822/MSB3823) à cause des `.resx` contenant des images/icônes ⇒ runner Windows + `setup-msbuild` obligatoires.
  *Même comportement sur le projet d'origine.*

### Tests (`tests.yml`)
- Projet `tests\WinVOIE.Tests` : xUnit 2.9.3, ancien format `.vbproj` + `packages.config`, référence le projet `WinVOIE`.
- 2 tests sur `Fichier_Enreg_Modifie` (détection d'un fichier d'enregistrement modifié à la main) : fichier intact → non signalé, valeur changée → signalé.
- Exécutés par `vstest.console` ; `dotnet test` sur ce format n'exécuterait rien et renverrait 0.
- Rapport `resultats.trx` en artefact (`if: always()`), jamais versionné (`.gitignore`).
- Démo : casser `Calcul_Signature` dans une PR → `tests` rouge, PR non fusionnable.

### CodeQL
- **VB.NET n'est pas supporté** par CodeQL. Le "default setup" ne proposera que le langage *GitHub Actions* (les workflows).
- Ne jamais ajouter `csharp` à CodeQL pour ce dépôt : il ne lirait pas les `.vb`.

### Code scanning – Roslyn (`code-scanning.yml`, catégorie `roslyn-vbnet`)
- ~50 alertes, presque toutes **qualité** : CA1031 (catch générique), CA2000 (Dispose manquant), CA1822, CA1861, CA1862, CA1854, CA2208.
- **1 seule alerte sécurité** : CA3075 – `XmlDocument.Load` non sécurisé (`Module_Licenses.vb`).
- SecurityCodeScan : **0 alerte**.
- *Projet d'origine : 2452 alertes, même répartition, 1 seule sécurité (CA3075).*

### Code scanning – DevSkim (catégorie `devskim`)
- 3 × **DS106863 "Do not use DES"** = **faux positifs** : le mot français « DES » (« IMPRESSION DES ENREGISTREMENTS »).
- 2 × DS176209 (commentaires TODO).
- *Projet d'origine : 40 faux positifs « DES » + 5 TODO.* → bon exercice de tri (Dismiss > False positive).

### Dependabot
- **Alerts : 0** — aucun des 13 packages n'a de vulnérabilité connue à ce jour (audit NuGet vérifié).
- **Version updates** : plusieurs PR (Microsoft.Extensions.* 8.x, System.Memory, System.Buffers…, et les actions GitHub).
- `TwinCAT.Ads.dll` / `Fde.Vmp60.Network.dll` (références `HintPath` vers `dll\`) : **invisibles** pour le dependency graph et Dependabot.

### Secret scanning
- Rien de détecté : aucun secret au format d'un fournisseur dans le dépôt.

## 4. Scénarios de démo

### A. PR qui introduit un package vulnérable (jouée : PR #21, brouillon, non fusionnée)
Branche `demo/newtonsoft-vulnerable`, commit `build(deps): rétrograde Newtonsoft.Json en 12.0.3` :
`packages.config` et `HintPath`/`Version` du `.vbproj` passés de 13.0.4 à 12.0.3. PR en **brouillon**, description `Refs #2`.

| Contrôle | Résultat |
|---|---|
| `revue-dependances` | **rouge** + commentaire « 1 vulnerable package » (GHSA-5crp-9r3c-p9vr, High) |
| `build` (restauration MSBuild) | vert : `NU1903` dans le journal, **sans annotation** dans la PR |
| `tests` | vert |
| Dependabot (Security) | **aucune alerte** : il ne surveille que `main` |

Sans la revue des dépendances, la faille passait dans une PR entièrement verte.

### L. PR qui casse un test (jouée : PR #22, brouillon, non fusionnée)
Branche `demo/test-casse`, commit `refactor(crc): sort la longueur du texte de la boucle de signature`,
« aucun changement de comportement attendu » : une ligne, la longueur de la **clé** au lieu de celle du texte.
Le build est vert, `tests` est **rouge** (`Valeur_modifiee_a_la_main_est_detectee`) : la signature ignore les données,
un enregistrement falsifié n'est plus détecté.
À rejouer en séance : passer la PR en « Ready for review » et la faire approuver ; le bouton de fusion reste grisé (revue humaine et contrôle automatique sont deux barrières indépendantes).

### B. Push protection
1. Créer un token GitHub (fine-grained, **aucune permission**, expiration 1 jour).
2. Le coller dans `WinVOIE\app.config`, commit, `git push` → **bloqué**.
3. Supprimer le token sur GitHub, annuler le commit (`git reset HEAD~1`).

### C. Tri des alertes
- DevSkim « DES » → *Dismiss : False positive* ; CA1031 → *Won't fix* ; CA3075 → corriger (`XmlReaderSettings` avec `DtdProcessing.Prohibit`).

## 5. Ce que les outils NE voient PAS (revue humaine)

| Problème | Où |
|---|---|
| Mots de passe d'accès en dur, en clair et en double casse (`FERROSUP`/`ferrosup`…) | `Frm_util_Menu.vb`, `Frm_Reglage_Zero_Statique.vb` |
| Mot de passe SMTP stocké en clair sur le poste | `C:\WVOIE\MAIL\mail_parametres.con` (`initialisation.vb`) |
| L'export « contexte SAV » zippe **tout** `C:\WVOIE`, donc le mot de passe mail, et l'envoie au SAV | `ContextZip.vb` |
| Serveur TCP en écoute sur **toutes** les interfaces, sans authentification | `TcpCommandClient.vb` (`IPAddress.Any`, port 5001) |
| Nom de fichier saisi par l'opérateur concaténé au chemin (`..\..\`) | `Frm_Choix_File_Ref.vb` |
| Clé de « signature » des fichiers en dur dans le code | `Verification_CRC.vb` |
| Détail complet des exceptions (stack trace, poste, utilisateur) affiché à l'opérateur | `Frm_Exception.vb` |
| Chemin perso d'un développeur dans le projet | `WinVOIE.vbproj` (`PublishUrl`) |
| DLL binaires versionnées ; fichiers parasites à la racine (`ile.cs`, `temp_enreg.vb`, retirés par la PR de l'issue #15) | `WinVOIE\dll`, racine |
| Référence `System.ValueTuple` absente de `packages.config` ; `ConvertToUTF8BOM.ps1` référencé mais absent ; `OptionsFileService.vb` présent mais non compilé | `WinVOIE.vbproj` |
