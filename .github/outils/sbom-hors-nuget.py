# Ajoute au SBOM CycloneDX les DLL de fournisseurs versionnées dans WinVOIE/dll :
# CycloneDX ne connaît que les paquets NuGet, ces composants n'y figurent pas (jours 4 et 5).
# Usage : python3 sbom-hors-nuget.py <bom.json> <dossier des DLL>
import hashlib
import json
import os
import sys

# Liste à tenir à jour avec le tableau « Composants tiers hors NuGet » du README
COMPOSANTS = [
    {"fichier": "TwinCAT.Ads.dll", "nom": "TwinCAT.Ads", "version": "4.3.30",
     "editeur": "Beckhoff Automation", "licence": "Propriétaire Beckhoff (DLL factice de démonstration)"},
    {"fichier": "Fde.Vmp60.Network.dll", "nom": "Fde.Vmp60.Network", "version": "1.2.0",
     "editeur": "Fournisseur Fde", "licence": "Propriétaire (DLL factice de démonstration)"},
]

bom_chemin, dossier = sys.argv[1], sys.argv[2]
with open(bom_chemin, encoding="utf-8") as f:
    bom = json.load(f)

for c in COMPOSANTS:
    with open(os.path.join(dossier, c["fichier"]), "rb") as f:
        empreinte = hashlib.sha256(f.read()).hexdigest()
    bom.setdefault("components", []).append({
        "type": "library",
        "bom-ref": c["nom"] + "@" + c["version"],
        "name": c["nom"],
        "version": c["version"],
        "publisher": c["editeur"],
        "description": "DLL hors NuGet, versionnée dans WinVOIE/dll",
        "licenses": [{"license": {"name": c["licence"]}}],
        "hashes": [{"alg": "SHA-256", "content": empreinte}],
    })
    print("ajouté :", c["nom"], c["version"], empreinte)

with open(bom_chemin, "w", encoding="utf-8") as f:
    json.dump(bom, f, ensure_ascii=False, indent=2)
