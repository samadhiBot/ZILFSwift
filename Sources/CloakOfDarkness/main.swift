//import Foundation
//import ZILFCore
//
//struct CloakOfDarknessApp {
//    static func main() async throws {
//        // Create the game
//        let game = await CloakOfDarkness()
//
//        // Set up terminal resize handling (if in terminal mode)
//        #if os(macOS) || os(Linux)
//        await setupSignalHandler(game: game)
//        #endif
//
//        // Start the game
//        try await game.start()
//    }
//}
