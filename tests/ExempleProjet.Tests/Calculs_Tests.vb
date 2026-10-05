Imports Xunit

''' <summary>
''' Exemple de tests : un test par comportement attendu, nommé comme une phrase.
''' À remplacer par les tests du vrai code du projet.
''' </summary>
Public Class Calculs_Tests

    <Fact>
    Public Sub Deux_plus_trois_donne_cinq()
        Assert.Equal(5, Additionner(2, 3))
    End Sub

    <Fact>
    Public Sub Ajouter_zero_ne_change_rien()
        Assert.Equal(7, Additionner(7, 0))
    End Sub

End Class
