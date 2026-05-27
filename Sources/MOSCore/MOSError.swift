import Foundation

public enum MOSError: Error, CustomStringConvertible, Equatable {
    case androidSDKNotFound
    case toolNotFound(String)
    case commandFailed(command: String, exitCode: Int32, stderr: String)
    case invalidArgument(String)
    case noRunningDevice

    public var description: String {
        switch self {
        case .androidSDKNotFound:
            return "Android SDK not found. Set ANDROID_HOME or ANDROID_SDK_ROOT, or install it at ~/Library/Android/sdk."
        case .toolNotFound(let name):
            return "Required Android SDK tool not found: \(name)."
        case .commandFailed(let command, let exitCode, let stderr):
            let message = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return "Command failed (\(exitCode)): \(command)\(message.isEmpty ? "" : "\n\(message)")"
        case .invalidArgument(let message):
            return message
        case .noRunningDevice:
            return "No running Android emulator device was found."
        }
    }
}

extension CommandResult {
    func requireSuccess() throws -> CommandResult {
        guard succeeded else {
            throw MOSError.commandFailed(
                command: ([executable] + arguments).joined(separator: " "),
                exitCode: exitCode,
                stderr: stderr
            )
        }
        return self
    }
}
