# Charte Git de l'équipe WinVOIE

Version 1, adoptée le 03/10/2026 par LaPolaris et ladel1 (dépôt de démonstration)
Prochaine révision : 03/04/2027

Chaque règle ci-dessous est en place et vérifiée dans ce dépôt ; la preuve est indiquée entre parenthèses.

## 1. Dépôt et accès

Organisation GitHub : `lapolaris-formation`
Offre GitHub : Free, dépôt **public** (fonctions de sécurité gratuites sur dépôt public)
Dépôts concernés : `demo-vb-security`

| Personne | Rôle GitHub | Équipes |
|---|---|---|
| LaPolaris | propriétaire de l'organisation | — |
| ladel1 | membre | `developpeurs` (Write), `responsables` (Maintain) |

Les équipes sont ajoutées à chaque nouveau dépôt : le droit de base de l'organisation (Read)
ne donne ni l'écriture ni une approbation valable.
Chaque équipe de relecteurs compte au moins deux personnes : **écart actuel**, une seule personne
par équipe (ladel1) ; l'auteur d'une PR touchant `.github/` doit donc toujours être LaPolaris.

Authentification à deux facteurs : **non exigée au niveau de l'organisation**, décision écrite :
l'exiger retirerait les membres qui ne l'ont pas configurée. À exiger dès que chacun l'a activée.

Revue des accès : à chaque arrivée, départ ou changement de poste, et au minimum une fois par an.
Responsable de cette revue : LaPolaris

Identité des commits : nom réel ou pseudonyme du compte, adresse noreply GitHub,
configurée par dépôt si un poste porte plusieurs comptes.
Encodage des fichiers : `.editorconfig` versionné (UTF-8 avec BOM pour le VB, sans BOM pour `.gitleaks.toml`,
indentation de 2 espaces pour le YAML).

## 2. Stratégie de branches

Modèle retenu : GitHub Flow avec branches de release

- `main` : protégée par le ruleset `protection-main`, bypass list vide, toujours en état livrable
- branches de travail : courtes, une par issue, supprimées après fusion (réglage du dépôt)
- `release/x.y` : créée depuis le tag livré si un correctif doit partir sur une version installée ;
  le ruleset couvre déjà `release/**`
- branches `demo/*` : conservées, jamais fusionnées, pour relire le code des démonstrations

Durée de vie maximale d'une branche de travail : 5 jours ouvrés

Les branches de release ne sont pas surveillées par Dependabot :
leur audit de dépendances est fait par le référent sécurité à chaque correctif reporté.

## 3. Nommage des branches

Format : `type/numéro-libellé-court`, le numéro étant celui de l'issue **lu sur GitHub après sa création**.
Issues et pull requests partagent la même numérotation, et Dependabot en consomme : ne jamais deviner un numéro.

Types autorisés : `feat`, `fix`, `hotfix`, `refactor`, `test`, `ci`, `chore`, `docs`, `demo`

Exemples : `fix/17-mots-de-passe-en-dur`, `ci/19-detection-secrets`

Interdits : prénoms, `test`, `v2`, `final`, `ok`

## 4. Messages de commit

Format : `type(portée): description`

Types : `feat`, `fix`, `refactor`, `test`, `docs`, `build`, `ci`, `chore`, `perf`

Un fichier du dépôt qui ne change pas le logiciel livré (modèle, CODEOWNERS, workflow)
se commite en `docs`, `chore` ou `ci`, jamais en `fix`.

Rupture de compatibilité : `!` après le type, ou pied `BREAKING CHANGE:`

Un correctif de sécurité explique dans le corps la faille et sa correction (PR #18, #31).
Le lien vers l'issue s'écrit `Refs #` dans le commit ; `Closes #` dans la pull request.
Commit de fusion : message proposé par GitHub (« Merge pull request #… »).
Commits de Dependabot : préfixe `build` (NuGet) ou `ci` (actions), imposé par `dependabot.yml`.
Signature des commits : non

## 5. Issues

Tout changement commence par une issue. Aucune exception.

Modèles disponibles : anomalie, évolution.
Une vulnérabilité **non publiée** ne s'ouvre jamais en issue publique : signalement privé GitHub
ou adresse de `SECURITY.md`. Une faille déjà publique (CVE d'un paquet, alerte d'outil sur dépôt public)
peut faire l'objet d'une issue `securite`.

Labels :
- nature : `securite`, `anomalie`, `evolution`, `documentation`
- priorité : `p1-bloquant`, `p2-important`, `p3-normal`
- outillage : `dependances`, `ci`

Le label `securite` est obligatoire sur tout correctif de sécurité.
Il conditionne la production de la documentation réglementaire.

## 6. Pull requests

Toute modification de `main` passe par une pull request (ruleset, `GH013` sinon).

La pull request :
- utilise le modèle du dépôt, rempli par son auteur
- référence l'issue par `Closes #` (contrôle bloquant `issue-liee`)
- a un titre au format `type(portée): description` (contrôle bloquant `titre-pr`)
- porte au moins un label de nature
- met à jour le changelog si le comportement du logiciel change

Mode de fusion : create a merge commit, seul mode autorisé
Mise à jour d'une branche en retard : bouton « Update branch » (fusion de `main`), jamais de rebase forcé
Taille souhaitable : moins de 15 fichiers modifiés
Démonstration ou essai sans intention de fusionner : pull request en **brouillon**

## 7. Revue

Nombre d'approbations requises : 1, et celle des propriétaires de code (CODEOWNERS)
L'auteur d'une pull request ne l'approuve jamais, propriétaire compris.
Une nouvelle poussée annule les approbations précédentes.

Délai de réponse attendu d'un relecteur : 1 jour ouvré

Niveaux de commentaire, et bouton GitHub correspondant :
- `blocker` : bloque la fusion → Request changes
- `suggestion` : à la main de l'auteur → Comment
- `nit` : détail, non bloquant → Comment
- `question` : attend une réponse → Comment
- aucun `blocker` → Approve

Seuls les `blocker` empêchent la fusion.
Tout fil est résolu avant fusion, par correction ou par réponse motivée (réglage du ruleset).

En cas de désaccord persistant entre l'auteur et le relecteur :
arbitrage par l'équipe `responsables`. Jamais de fusion en force.

## 8. Tests et intégration continue

Le pipeline doit être vert avant toute fusion.
Contrôles requis dans le ruleset : `build`, `tests`, `revue-dependances`, `issue-liee`, `detection-secrets`, `titre-pr`
Responsable de la mise à jour du ruleset quand un job change de nom : équipe `responsables`

Le job `build` vérifie aussi que chaque assembly livré se charge avec la configuration de l'exécutable :
un build vert ne prouve pas que le programme démarre (PR Dependabot #11 et #27).

Un test est écrit :
- pour toute nouvelle classe métier
- pour tout défaut corrigé, reproduisant le défaut avant correction (PR #18, #31)

Couverture visée sur le périmètre métier : non mesurée à ce jour, point ouvert
Périmètre exclu : interface, code généré

Que fait-on d'une pull request dont les tests échouent :
elle n'est pas fusionnable (contrôle `tests` requis) ; l'auteur corrige ou retire la modification.

Épinglage du runner et du SDK : non (`windows-latest`, `ubuntu-latest`), écart de version accepté
Usage de Copilot et d'« Explain error » : autorisé sur ce dépôt public, interdit sur un dépôt client sans accord écrit

## 9. Versions et livraisons

Format des tags : `vMAJEUR.MINEUR.CORRECTIF` (premier tag : `v6.73.1`)
La version de l'assembly est alignée sur le tag par le workflow `release`.

Règle d'incrément :
- `fix` : correctif
- `feat` : mineur
- rupture de compatibilité : majeur

Qui pose les tags : équipe `responsables`, sur `main` après fusion

Toute version livrée à un client donne lieu à (workflow `release`, déclenché par le tag) :
- un tag
- une release GitHub, publiée sans l'option préversion
- le binaire, construit par le pipeline depuis le tag, attaché
- le SBOM (`WinVOIE-<version>.cdx.json`), DLL de fournisseurs comprises, attaché
- une attestation de provenance sur l'exécutable et le livrable
- une entrée de changelog

Binaire, SBOM et attestation partent du même tag.
Signature de code : non en place (certificat de test uniquement, à la main)
Installateur : produit à la main avec Visual Studio (`Setup.vdproj`, non compilable par MSBuild)

Archivage des livrables et de leur documentation :
releases GitHub, plus copie hors GitHub à définir, durée 10 ans

## 10. Sécurité

Aucun secret dans le dépôt, ni dans le code (mot de passe comparé en dur compris : PR #18).
Un secret poussé est révoqué immédiatement, sans attendre le nettoyage de l'historique.
Les formats de secrets propres au produit ont une règle de détection (`.gitleaks.toml`).
Une trouvaille historique n'est acquittée dans `.gitleaksignore` qu'avec sa décision écrite,
et ce fichier est sous CODEOWNERS `responsables`.

Traitement des alertes et des pull requests Dependabot :
- revue hebdomadaire, le lundi (jour de passage de Dependabot)
- une issue par décision, y compris quand on ne fusionne pas (issue #25)
- une PR Dependabot verte se relit comme les autres : vérifier ce qu'elle livre, pas seulement qu'elle compile
- montées majeures de Microsoft.Extensions, Microsoft.Bcl et Pkcs ignorées jusqu'à la migration coordonnée avec PDFsharp

Inventaire des DLL de fournisseurs (hors NuGet) : tenu par le référent sécurité,
dans le README et dans `.github/outils/sbom-hors-nuget.py`
`SECURITY.md` est sous CODEOWNERS `responsables` : ses délais engagent l'entreprise.

Référent sécurité : LaPolaris

## 11. Procédure d'urgence

Une livraison urgente peut justifier un contournement des règles.

Qui peut l'autoriser : le propriétaire de l'organisation (LaPolaris)
Dans quels cas : machine d'un client à l'arrêt, ou vulnérabilité activement exploitée

Le ruleset n'a pas de bypass : le contournement consiste à retirer temporairement une règle,
action tracée dans le journal d'audit de l'organisation.

Régularisation obligatoire sous 2 jours ouvrés :
- règle remise en place
- revue a posteriori de la modification
- issue de suivi décrivant ce qui s'est passé
- entrée de changelog

Un contournement non régularisé est un manquement.

## 12. Révision de la charte

Cette charte est révisée tous les six mois, ou à la demande
de tout membre de l'équipe.

Les modifications passent par une pull request sur ce fichier.
