# Checklist de mise en place du dépôt

Procédure pour un nouveau dépôt créé à partir de ce modèle, dans l'ordre.
**Une étape se coche dans la pull request qui la réalise**, avec sa preuve : numéro de PR, commit ou réglage vérifié.
Une étape faite uniquement dans les réglages GitHub se coche dans la PR suivante.

Légende : `[x]` fait et vérifié, `[ ]` à faire.

## Fondations

- **A. Poste**
  - [ ] Identité des commits : nom du compte, adresse noreply GitHub (`git config user.name`, `user.email`)
  - [ ] Un second compte relecteur : l'auteur n'approuve jamais sa propre PR
- **B. Organisation**
  - [ ] Équipes `developpeurs` (Write) et `responsables` (Maintain) ajoutées au dépôt ; au moins deux personnes par équipe
  - [ ] Authentification à deux facteurs exigée pour l'organisation, ou décision écrite si elle ne l'est pas encore
- **C. Adapter le modèle** (voir `README.md`)
  - [ ] Projet renommé ; lignes `env:` des workflows adaptées
  - [ ] `ORGANISATION` remplacé dans `.github/CODEOWNERS`
  - [ ] Valeurs entre `< >` remplacées dans `SECURITY.md` et `docs/charte-git.md`
  - [ ] Dossiers des `packages.config` listés dans `.github/dependabot.yml`
- **D. Dépôt et premier push**
  - [ ] Dépôt créé vide ; seul push direct sur `main` : le premier
- **E. Fichiers d'hygiène**
  - [ ] `.gitattributes`, `.editorconfig`, `.gitignore` dans le premier commit
  - [ ] Aucune clé ni certificat suivi : `git ls-files "*.pfx" "*.snk"` vide
  - [ ] Aucun marqueur de conflit : `git grep -n "<<<<<<<\|>>>>>>>"` vide
- **F. README**
  - [ ] Compilation, livraison, liste des DLL hors NuGet
- **G. Réglages des pull requests**
  - [ ] Merge commit seul, branches supprimées après fusion
- **H. Ruleset de `main`**
  - [ ] Cibles `main` et `release/**`, bypass list vide
  - [ ] 1 approbation, approbations périmées annulées, Code Owners, résolution des fils, merge seul
  - [ ] Vérifié : `git push` direct sur `main` refusé (`GH013`), propriétaire compris
- **I. Labels**
  - [ ] Nature (`securite`, `anomalie`, `evolution`, `documentation`), priorité, outillage (`dependances`, `ci`) ; labels par défaut supprimés
- **J. Fichiers de collaboration**
  - [ ] CODEOWNERS, modèle de PR, modèles d'issue anomalie et évolution
  - [ ] Vérifié : revue des `responsables` demandée automatiquement sur une PR qui touche `.github/`
  - [ ] Vérifié : `gh api repos/<organisation>/<depot>/codeowners/errors` renvoie `{"errors":[]}`

## Intégration continue

- **K. Pipeline**
  - [ ] Workflows `build` et `tests` verts sur une première PR
  - [ ] Binaires et résultats de tests (`.trx`) en artefact
- **L. Contrôles requis dans le ruleset**
  - [ ] `build`, `tests`
  - [ ] `issue-liee`, `titre-pr`
  - [ ] `detection-secrets`
  - [ ] `revue-dependances` (dépôt public, ou licence Code Security sur dépôt privé)
  - [ ] Vérifié : une PR qui casse un test ne peut pas être fusionnée

## Sécurité

- **M. Advanced Security**
  - [ ] Dependency graph, Dependabot alerts, Dependabot malware alerts, Dependabot security updates
  - [ ] Private vulnerability reporting (dépôt public)
  - [ ] Secret Protection, puis Push protection (dépôt public, ou licence Secret Protection)
- **N. Dependabot**
  - [ ] `dependabot.yml` fusionné ; **Insights**, **Dependency graph**, onglet **Dependabot** sans erreur
  - [ ] Premières PR de Dependabot qualifiées par écrit dans une issue avant toute fusion
- **O. Analyse de code**
  - [ ] Analyseurs Roslyn et DevSkim : résultats dans Code scanning (dépôt public, ou licence Code Security)
  - [ ] Alertes triées : corrigées, ou fermées avec un motif écrit
- **P. Secrets**
  - [ ] Recherche des mots de passe écrits dans le code : `git grep -n -i "password\|motdepasse\|mdp\|pwd"`
  - [ ] Règles `.gitleaks.toml` pour les formats propres au projet, testées sur exemples positifs et négatifs
  - [ ] Job `detection-secrets` vert ; toute trouvaille historique révoquée, puis acquittée avec sa décision
- **Q. Politique de sécurité**
  - [ ] `SECURITY.md` : versions prises en charge, canal privé, délais validés par la direction

## Livraison

- **R. Version**
  - [ ] Format `vMAJEUR.MINEUR.CORRECTIF` ; `AssemblyVersion` alignée sur le tag par le workflow `release`
  - [ ] `CHANGELOG.md` tenu à jour
- **S. Release**
  - [ ] DLL hors NuGet déclarées dans `.github/outils/composants-hors-nuget.json`
  - [ ] Premier tag posé : release publiée par le workflow, avec le livrable et le SBOM
  - [ ] Provenance vérifiée : `gh attestation verify <Projet>.exe --owner <organisation>` (dépôt public, ou GitHub Enterprise Cloud)
  - [ ] Signature horodatée de l'exécutable (certificat OV, EV ou signature cloud)
- **T. Charte et plan**
  - [ ] `docs/charte-git.md` adaptée et adoptée par PR
  - [ ] Plan d'action CRA daté, responsables nommés
