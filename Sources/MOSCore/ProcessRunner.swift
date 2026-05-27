import Foundation

public struct CommandResult: Sendable, Equatable {
    public let executable: String
    public let arguments: [String]
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public var succeeded: Bool {
        exitCode == 0
    }
}

public enum ProcessRunnerError: Error, CustomStringConvertible {
    case missingExecutable(URL)
    case timedOut(command: String, timeout: TimeInterval)
    case failedToDecodeOutput

    public var description: String {
        switch self {
        case .missingExecutable(let url):
            return "Missing executable: \(url.path)"
        case .timedOut(let command, let timeout):
            return "Command timed out after \(Int(timeout))s: \(command)"
        case .failedToDecodeOutput:
            return "Failed to decode process output as UTF-8."
        }
    }
}

public protocol ProcessRunning {
    func run(
        _ executable: URL,
        arguments: [String],
        environment: [String: String]?,
        input: String?,
        timeout: TimeInterval?
    ) throws -> CommandResult

    func launchDetached(
        _ executable: URL,
        arguments: [String],
        environment: [String: String]?
    ) throws -> Int32
}

public final class FoundationProcessRunner: ProcessRunning {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func run(
        _ executable: URL,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        input: String? = nil,
        timeout: TimeInterval? = nil
    ) throws -> CommandResult {
        guard fileManager.isExecutableFile(atPath: executable.path) else {
            throw ProcessRunnerError.missingExecutable(executable)
        }

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = mergedEnvironment(environment)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        var stdinPipe: Pipe?
        if input != nil {
            let pipe = Pipe()
            process.standardInput = pipe
            stdinPipe = pipe
        }

        let group = DispatchGroup()
        group.enter()
        process.terminationHandler = { _ in
            group.leave()
        }

        try process.run()

        if let input {
            let data = Data(input.utf8)
            stdinPipe?.fileHandleForWriting.write(data)
            try? stdinPipe?.fileHandleForWriting.close()
        }

        if let timeout {
            let result = group.wait(timeout: .now() + timeout)
            if result == .timedOut {
                process.terminate()
                _ = group.wait(timeout: .now() + 2)
                throw ProcessRunnerError.timedOut(
                    command: ([executable.path] + arguments).joined(separator: " "),
                    timeout: timeout
                )
            }
        } else {
            process.waitUntilExit()
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        guard
            let stdout = String(data: stdoutData, encoding: .utf8),
            let stderr = String(data: stderrData, encoding: .utf8)
        else {
            throw ProcessRunnerError.failedToDecodeOutput
        }

        return CommandResult(
            executable: executable.path,
            arguments: arguments,
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )
    }

    public func launchDetached(
        _ executable: URL,
        arguments: [String] = [],
        environment: [String: String]? = nil
    ) throws -> Int32 {
        guard fileManager.isExecutableFile(atPath: executable.path) else {
            throw ProcessRunnerError.missingExecutable(executable)
        }

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.environment = mergedEnvironment(environment)

        let nullURL = URL(fileURLWithPath: "/dev/null")
        let nullOut = try FileHandle(forWritingTo: nullURL)
        let nullErr = try FileHandle(forWritingTo: nullURL)
        process.standardOutput = nullOut
        process.standardError = nullErr

        try process.run()
        return process.processIdentifier
    }

    private func mergedEnvironment(_ overrides: [String: String]?) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        overrides?.forEach { key, value in
            environment[key] = value
        }
        return environment
    }
}
