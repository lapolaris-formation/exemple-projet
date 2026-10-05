// Vérifie que chaque assembly référencé par les binaires livrés se charge réellement,
// avec la configuration de l'exécutable (redirections de liaison, probing).
//
// Pourquoi : sur un projet .NET Framework, une mise à jour de paquet peut donner un build
// et des tests verts, puis une FileLoadException au chargement chez le client
// (PR Dependabot #11 et #27, issue #32).
//
// Usage (CI) : compilé dans une copie de bin\Release, avec WinVOIE.exe.config copié en
// verifier-liaisons.exe.config pour que le chargeur applique exactement les mêmes règles.
// Code C# 5 : compilable par le csc de .NET Framework, sans dépendance.
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

class VerifierLiaisons
{
    static int Main()
    {
        string dossier = AppDomain.CurrentDomain.BaseDirectory;
        string moiMeme = Path.GetFileName(Assembly.GetExecutingAssembly().Location);
        var dejaVerifiees = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        int fichiers = 0, references = 0, erreurs = 0;

        foreach (string fichier in Directory.GetFiles(dossier))
        {
            string ext = Path.GetExtension(fichier).ToLowerInvariant();
            if ((ext != ".dll" && ext != ".exe") || Path.GetFileName(fichier).Equals(moiMeme, StringComparison.OrdinalIgnoreCase))
                continue;

            Assembly assembly;
            try { assembly = Assembly.LoadFrom(fichier); }
            catch (BadImageFormatException) { continue; }   // DLL native : pas d'assembly .NET
            fichiers++;

            foreach (AssemblyName reference in assembly.GetReferencedAssemblies())
            {
                if (!dejaVerifiees.Add(reference.FullName))
                    continue;
                references++;
                try
                {
                    Assembly.Load(reference);
                }
                catch (Exception e)
                {
                    erreurs++;
                    Console.WriteLine("ECHEC  " + reference.FullName);
                    Console.WriteLine("       requis par " + Path.GetFileName(fichier) + " : " + e.GetType().Name + " : " + e.Message.Split('\n')[0].Trim());
                }
            }
        }

        Console.WriteLine(fichiers + " binaires, " + references + " références vérifiées, " + erreurs + " en échec.");
        return erreurs == 0 ? 0 : 1;
    }
}
