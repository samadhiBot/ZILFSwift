extension GameObject {
    /// The set of `GameObject` categories.
    public enum Category: Equatable {
        case global
        case localGlobal([GameObject.ID])
        case object
        case player
        case room
    }
}
