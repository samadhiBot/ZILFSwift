import ZILFCore

struct HelloWorldGameApp {
    static func main() async throws {
        let outputManager = StandardOutputManager()

        let helloWorld = HelloWorldGame(output: outputManager.output)

        let engine = GameEngine(
            game: helloWorld,
            outputManager: outputManager
        )
        engine.start()
    }
}
