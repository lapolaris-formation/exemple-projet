# Ajoute au SBOM CycloneDX les DLL de fournisseurs livrées sans NuGet :
# CycloneDX ne connaît que les paquets NuGet, ces composants n'y figurent pas.
# Usage : python3 sbom-hors-nuget.py <bom.json> <liste des composants (.json)>
# La liste est .github/outils/composants-hors-nuget.json ; vide, le SBOM reste inchangé.
import hashlib
import json
import sys

bom_chemin, liste_chemin = sys.argv[1], sys.argv[2]
with open(liste_chemin, encoding="utf-8") as f:
    composants = json.load(f)["composants"]
if not composants:
    print("aucun composant hors NuGet déclaré")
    sys.exit(0)

with open(bom_chemin, encoding="utf-8") as f:
    bom = json.load(f)

for c in composants:
    # chemin de la DLL depuis la racine du dépôt : l'empreinte prouve quel fichier est livré
    with open(c["fichier"], "rb") as f:
        empreinte = hashlib.sha256(f.read()).hexdigest()
    bom.setdefault("components", []).append({
        "type": "library",
        "bom-ref": c["nom"] + "@" + c["version"],
        "name": c["nom"],
        "version": c["version"],
        "publisher": c["editeur"],
        "description": "DLL hors NuGet, versionnée dans " + c["fichier"],
        "licenses": [{"license": {"name": c["licence"]}}],
        "hashes": [{"alg": "SHA-256", "content": empreinte}],
    })
    print("ajouté :", c["nom"], c["version"], empreinte)

with open(bom_chemin, "w", encoding="utf-8") as f:
    json.dump(bom, f, ensure_ascii=False, indent=2)
