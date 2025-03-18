import Foundation
import Dispatch

/// Setup signal handler for terminal resize events
@MainActor public func setupSignalHandler(game: Game) {
    let sigwinchSource = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .main)
    sigwinchSource.setEventHandler {
        Task { @MainActor in
            game.handleTerminalResize()
        }
    }
    sigwinchSource.resume()
}
