import Foundation
import ZILFCore

struct HelloWorldGameApp {
    static func main() async throws {
        // Create the game
        let game = await HelloWorldGame()

        // Set up terminal resize handling (if in terminal mode)
        #if os(macOS) || os(Linux)
        await setupSignalHandler(game: game)
        #endif

        // Start the game
        try await game.start()
    }
}
