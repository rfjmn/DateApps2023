#!/usr/bin/env swift
// Build and test the checked-in target inventory with Foundation only.
import Foundation

struct Target: Decodable {
    let kind: String
    let name: String
    let path: String?
    let project: String?
    let workspace: String?
    let scheme: String?
}

struct Matrix: Encodable {
    struct Entry: Encodable {
        let index: Int
        let name: String
    }
    let include: [Entry]
}

struct VerificationError: Error, CustomStringConvertible {
    let description: String
}

struct CommandFailure: Error {
    let status: Int32
}

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

func output(_ value: String, to handle: FileHandle = .standardOutput) {
    handle.write(Data((value + "\n").utf8))
}

func required(_ value: String?, field: String) throws -> String {
    guard let value = value, !value.isEmpty else {
        throw VerificationError(description: "Missing target field: \(field)")
    }
    return value
}

func command(for target: Target, scratch: String) throws -> [String] {
    switch target.kind {
    case "package":
        return ["swift", "test", "--package-path", try required(target.path, field: "path"),
                "--scratch-path", scratch, "--jobs", "2"]
    case "app":
        let container = target.workspace == nil ? "project" : "workspace"
        let path = try required(target.workspace ?? target.project, field: container)
        return ["xcodebuild", "-" + container, path,
                "-scheme", try required(target.scheme, field: "scheme"),
                "-destination", "generic/platform=iOS Simulator",
                "-derivedDataPath", scratch, "-jobs", "2", "CODE_SIGNING_ALLOWED=NO", "build"]
    default:
        throw VerificationError(description: "Unknown target kind: \(target.kind)")
    }
}

func verify(_ target: Target, index: Int, dryRun: Bool) throws {
    let scratch = FileManager.default.temporaryDirectory
        .appendingPathComponent("repository-quality-" + UUID().uuidString)
    let arguments = try command(for: target, scratch: scratch.path)
    if dryRun {
        let data = try JSONEncoder().encode(arguments)
        output(String(decoding: data, as: UTF8.self))
        return
    }
    try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: scratch) }
    output("[\(index)] \(target.name)")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments
    process.currentDirectoryURL = root
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw CommandFailure(status: process.terminationStatus)
    }
}

func main() throws {
    var arguments = Array(CommandLine.arguments.dropFirst())
    var list = false
    var dryRun = false
    var index: Int?
    while !arguments.isEmpty {
        switch arguments.removeFirst() {
        case "--help", "-h":
            output("Usage: swift Scripts/verify.swift [--list | --index N] [--dry-run]")
            return
        case "--list": list = true
        case "--dry-run": dryRun = true
        case "--index":
            guard index == nil, !arguments.isEmpty, let number = Int(arguments.removeFirst()) else {
                throw VerificationError(description: "--index requires one integer")
            }
            index = number
        default: throw VerificationError(description: "Unknown argument. Use --help for usage.")
        }
    }
    guard !list || (index == nil && !dryRun) else {
        throw VerificationError(description: "--list cannot be combined with --index or --dry-run")
    }
    let targets = try JSONDecoder().decode([Target].self,
        from: Data(contentsOf: root.appendingPathComponent("quality-targets.json")))
    if list {
        let matrix = Matrix(include: targets.enumerated().map { .init(index: $0.offset, name: $0.element.name) })
        output(String(decoding: try JSONEncoder().encode(matrix), as: UTF8.self))
        return
    }
    if let index = index, !targets.indices.contains(index) {
        throw VerificationError(description: "Index is outside quality-targets.json")
    }
    for current in index.map({ [$0] }) ?? Array(targets.indices) {
        try verify(targets[current], index: current, dryRun: dryRun)
    }
}

do {
    try main()
} catch let failure as CommandFailure {
    exit(failure.status)
} catch {
    output("Verification failed: \(error)", to: .standardError)
    exit(1)
}
