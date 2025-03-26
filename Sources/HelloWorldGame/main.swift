import ZILFCore

let outputManager = StandardConsole()

let helloWorld = HelloWorldGame(output: outputManager.output)

let engine = GameEngine(
    game: helloWorld,
    console: outputManager
)
try engine.start()
