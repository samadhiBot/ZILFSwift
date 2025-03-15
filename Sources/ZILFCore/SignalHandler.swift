import Foundation
import Dispatch

/// Setup signal handler for terminal resize events
public func setupSignalHandler(gameEngine: GameEngine) {
    let sigwinchSource = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .main)
    sigwinchSource.setEventHandler {
        Task { @MainActor in
            gameEngine.handleTerminalResize()
        }
    }
    sigwinchSource.resume()
}
