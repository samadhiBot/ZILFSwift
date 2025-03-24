/// <#Description#>
public enum GameObjectType: Equatable {
    case global
    case localGlobal([Room])
    case object
    case player
    case room
}
