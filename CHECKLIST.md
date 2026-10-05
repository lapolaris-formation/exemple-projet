# Checklist de mise en place du dépôt

Suivi de la procédure du `README.md` sur ce dépôt, de A à Z, dans l'ordre logique (jours 1 à 5).
**Une étape se coche dans la pull request qui la réalise**, avec sa preuve : numéro de PR, commit ou réglage vérifié.
Une étape faite uniquement dans les réglages GitHub se coche dans la PR suivante.

Légende : `[x]` fait et vérifié, `[ ]` à faire.

## Fondations (jours 1 et 2)

- **A. Poste**
  - [x] Identité des commits : `LaPolaris`, adresse noreply
  - [x] Second compte relecteur (`ladel1`) : l'auteur n'approuve jamais sa propre PR
- **B. Organisation `lapolaris-formation`**
  - [x] Équipes `developpeurs` (Write) et `responsables` (Maintain) ajoutées au dépôt : approbation de `ladel1` comptée « for developpeurs and responsables » (PR #13)
  - [ ] Authentification à deux facteurs exigée pour l'organisation : **non appliquée, décision** : l'exiger retirerait de l'organisation les membres sans 2FA (`ladel1`). À activer dès que chaque membre l'a configurée
- **C. Dépôt et premier push**
  - [x] Dépôt créé vide, seul push direct sur `main` : `625f19e`, `5602e08`, `42cae6b`
- **D. Fichiers d'hygiène**
  - [x] `.gitattributes`, `.editorconfig`, `.gitignore` dans le premier commit (`625f19e`)
  - [x] Aucune clé ni certificat suivi : `git ls-files "*.pfx" "*.snk"` vide
  - [x] Aucun marqueur de conflit : `git grep -n "<<<<<<<\|>>>>>>>"` vide
- **E. README**
  - [x] Compilation, livraison, liste des DLL hors NuGet (`42cae6b`)
- **F. Réglages des pull requests**
  - [x] Merge commit seul (« Merge pull request #3 », « #13 »), branches supprimées après fusion
- **G. Ruleset `protection-main`**
  - [x] Cibles `main` et `release/**`, bypass list vide
  - [x] 1 approbation, approbations périmées annulées, Code Owners, résolution des fils, merge seul
  - [ ] Démo : `git push` direct sur `main` refusé (`GH013`), propriétaire compris
- **H. Labels**
  - [x] Nature, priorité, outillage (`dependances`, `ci`) ; labels par défaut supprimés
- **I. Fichiers de collaboration (PR #3, issue #1)**
  - [x] CODEOWNERS, modèle de PR, modèles d'issue anomalie et évolution
  - [x] Constat : la PR qui installe le modèle a un formulaire vide ; la suivante (#13) est pré-remplie
  - [x] Revue des `responsables` demandée automatiquement sur `.github/` (PR #13)
  - [ ] Démo : décocher « Require review from Code Owners », constater que la PR fusionne sans eux, recocher

## Intégration continue (jour 3)

- **J. Pipeline (PR #13, issue #2)**
  - [x] Projet de tests séparé `tests/WinVOIE.Tests`, 2 tests sur `Fichier_Enreg_Modifie`
  - [x] Workflows `build` et `tests` sur `main` et `release/**`, binaires et `.trx` en artefact
  - [x] 7 contrôles verts dès la première exécution
- **K. Contrôles requis**
  - [x] `build`, `tests`, `revue-dependances` exigés dans le ruleset
  - [x] `issue-liee` et `detection-secrets` exigés (après la fusion de la PR #20)
  - [ ] `titre-pr` exigé (après la fusion de la PR de l'issue #23)
- **L. Démo : PR cassée bloquée**
  - [x] PR #22 (brouillon) : « refactor » d'une ligne qui casse `Calcul_Signature`, build vert, `tests` rouge, fusion impossible

## Sécurité (jour 4)

- **M. Advanced Security**
  - [x] Dependency graph, Dependabot alerts, Dependabot security updates
  - [x] Private vulnerability reporting activé (dépôt public)
  - [x] Dependabot malware alerts
  - [x] Secret Protection, puis Push protection
- **N. Dependabot**
  - [x] `dependabot.yml` : NuGet (`/WinVOIE`, `/tests/WinVOIE.Tests`) et actions, préfixes `build`/`ci`, label `dependances`
  - [x] Premières PR ouvertes, conformes à la convention (#4 à #12, #14)
- **O. Analyse de code**
  - [x] Analyseurs Roslyn et DevSkim sur `main` : 55 alertes dans Code scanning
- **P. Politique de sécurité**
  - [x] `SECURITY.md` : versions prises en charge, canal privé, délais (à valider par la direction) : PR de l'issue #15
- **Q. Nettoyage**
  - [x] Fichiers parasites retirés (`ile.cs`, `temp_enreg.vb`) : PR de l'issue #15
- **R. Mots de passe en dur**
  - [x] Constat : `Frm_util_Menu.vb:13` et `Frm_Reglage_Zero_Statique.vb:68` comparaient la saisie à des mots de passe écrits dans le code (trouvé par `git grep`, aucun outil ne les voit)
  - [x] Mots de passe sortis du code : empreintes PBKDF2 dans `acces.par`, créé par `outils/creer-acces.ps1` ; anciens mots de passe abandonnés ; 5 tests (issue #17)
- **S. Détection de secrets**
  - [x] Job `detection-secrets` : Gitleaks 8.30.1 lancé directement, empreinte SHA-256 vérifiée, tout l'historique (issue #19)
  - [x] `.gitleaks.toml` : 3 règles maison (comparaison en dur, configuration mail, chaîne de connexion), testées sur exemples positifs et négatifs
  - [x] `.gitleaksignore` : 2 trouvailles historiques acquittées, décision #17/#18 ; fichiers confiés aux `responsables`
  - [x] Lien vers une issue obligatoire dans chaque PR : job `issue-liee` (cas de la PR #18, `Closes #` sans numéro)
- **T. Démo A : paquet vulnérable**
  - [x] PR #21 (brouillon) : Newtonsoft.Json 12.0.3, `NU1903` au restore, `build` et `tests` verts, `revue-dependances` rouge, aucune alerte Dependabot
- **U. Démo B : push protection**
  - [ ] Faux secret au format fournisseur refusé au push ; mot de passe sans marqueur non vu
- **V. Tri des PR Dependabot**
  - [x] Qualification écrite dans l'issue #25 : aucune alerte de sécurité, 9 PR NuGet ouvertes avant le pipeline (aucun contrôle), en conflit entre elles
  - [x] Constat PR #11 : `packages.config` garde Logging.Abstractions 8.0.3, `.vbproj` et `app.config` passent à 10.0.12 ; build vert mais DLL absente de `bin\Release` (export PDF cassé chez le client)
  - [x] Décisions : #4, #5, #6, #11 fermées (migration 10.x à planifier avec PDFsharp) ; #7 à #10 et #12 fermées au profit du regroupement ; #14 (tests seulement, contrôles verts) acceptée
  - [x] `dependabot.yml` : `groups` mineures/correctives, `ignore` des majeures Microsoft.Extensions, Microsoft.Bcl, Pkcs
  - [ ] Issue de migration 8.x → 10.x avec PDFsharp, avant le 10/11/2026
  - [x] PR #27 (groupée) fermée : `System.Buffers` 4.0.5.0 livré sans redirection, `FileLoadException` prouvée ; #28 et #29 (tests seulement) acceptées
  - [x] Cause commune de #11 et #27 corrigée (issue #32) : redirections de liaison générées à la compilation ; sonde `.github/outils/VerifierLiaisons.cs` dans le job `build`, qui aurait bloqué les deux PR ; `PdfSharp.Snippets`/`Quality` inutilisés retirés (dépendance BouncyCastle manquante)
- **W. Tri des alertes Code scanning**
  - [ ] DevSkim « DES » : faux positifs (mot français), *Dismiss → False positive*
  - [x] CA3075 (`XmlDocument.Load`) : corrigé, DTD interdite, 2 tests ; l'ancien code développait une entité interne (issue #30)
  - [ ] CA1031, CA2000 : décision écrite (*Won't fix* ou plan)

## Livraison (jours 4 et 5)

- **X. Version**
  - [x] Format `vMAJEUR.MINEUR.CORRECTIF` décidé (avant : `L_WVOIE_UNI_6_73h`) : première version taguée `v6.73.1`, correctifs depuis 6.73h
  - [x] `AssemblyVersion` alignée sur le tag par le workflow `release` (6.73.1.0 vérifié sur l'exécutable) ; `CHANGELOG.md` : section 6.73.1
- **Y. Release**
  - [x] Workflow `release.yml` sur tag `v*` : binaire construit depuis le tag, SBOM CycloneDX du produit (13 paquets + TwinCAT et Fde avec empreinte SHA-256), attestation de provenance, release (issue #32)
  - [x] Tag `v6.73.1` posé : release « WinVOIE 6.73.1 » publiée par le workflow (non préversion), avec `WinVOIE-6.73.1.zip` et `WinVOIE-6.73.1.cdx.json`
  - [ ] Signature horodatée avec certificat de test (à la main, hors pipeline)
- **Z. Charte et plan**
  - [x] `docs/charte-git.md` adoptée par PR : chaque règle renvoie à une preuve du dépôt
  - [x] `docs/plan-action-cra.md` daté, responsables nommés : 8 exigences de l'annexe I partie II avec preuve et écart, feuille de route en 4 périodes
