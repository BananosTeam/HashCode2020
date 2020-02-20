import Foundation

struct Library {
    let numberOfBooks: Int
    let daysToSignup: Int
    let booksPerDay: Int
    let bookIndices: [Int]
}

struct Input {
    let numberOfBooks: Int
    let numberOfLibraries: Int
    let numberOfDays: Int
    let bookScores: [Int]
    let libraries: [Library]
}

struct ProcessedLibrary {
    let index: Int
    let numberOfBooks: Int
    let bookIndices: [Int]
}

struct Output {
    let numberOfLibraries: Int
    let libraries: [ProcessedLibrary]
}

enum Error: Swift.Error, CustomDebugStringConvertible {
    case arguments(_ message: String)
    case corruptedInput(_ input: String)

    var debugDescription: String {
        switch self {
        case .arguments(let message):
            return message
        case .corruptedInput(let input):
            return "Corrupted input:\n\(input)"
        }
    }
}

struct IO {
    func readInput(path: String) throws -> Input {
        let fileURL = fullURL(with: path)
        let rawString = try String(contentsOf: fileURL)
        var lines = rawString
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
        let metadata = lines
            .removeFirst()
            .split(separator: " ", omittingEmptySubsequences: true)
            .map { Int($0)! }
        let numberOfBooks = metadata[0]
        let numberOfLibraries = metadata[1]
        let numberOfDays = metadata[2]
        let bookScores = lines
            .removeFirst()
            .split(separator: " ", omittingEmptySubsequences: true)
            .map { Int($0)! }
        var libraries: [Library] = []
        for _ in 0..<numberOfLibraries {
            let metadata = lines
                .removeFirst()
                .split(separator: " ", omittingEmptySubsequences: true)
                .map { Int($0)! }
            let bookIndices = lines
                .removeFirst()
                .split(separator: " ", omittingEmptySubsequences: true)
                .map { Int($0)! }
            let numberOfBooks = metadata[0]
            let daysToSignup = metadata[1]
            let booksPerDay = metadata[2]
            libraries.append(.init(
                numberOfBooks: numberOfBooks,
                daysToSignup: daysToSignup,
                booksPerDay: booksPerDay,
                bookIndices: bookIndices
            ))
        }

        return Input(
            numberOfBooks: numberOfBooks,
            numberOfLibraries: numberOfLibraries,
            numberOfDays: numberOfDays,
            bookScores: bookScores,
            libraries: libraries
        )
    }

    func dumpOutput(_ output: Output, to path: String) throws {
        let initial = String(output.numberOfLibraries) + "\n"
        let outputString = output.libraries.enumerated().reduce(into: initial) { result, data in
            let (offset, library) = data
            result.append("\(library.index) \(library.numberOfBooks)\n")
            result.append(library.bookIndices.map(String.init).joined(separator: " "))
            if offset < output.libraries.count - 1 {
                result.append("\n")
            }
        }
        let fileURL = fullURL(with: path)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        FileManager.default.createFile(
            atPath: fileURL.path,
            contents: outputString.data(using: .utf8),
            attributes: nil
        )
    }

    private func fullURL(with path: String) -> URL {
        if path.starts(with: "/") {
            return URL(fileURLWithPath: path)
        } else if path.starts(with: "./") {
            let components = path.dropFirst().split(separator: "/", omittingEmptySubsequences: true).map(String.init)
            let currentDirectoryPath = FileManager.default.currentDirectoryPath
            let currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
            return components.reduce(currentDirectoryURL) { $0.appendingPathComponent($1) }
        } else {
            return URL(string: path)!
        }
    }
}

struct Arguments {
    struct Key {
        let short: String
        let long: String

        var shortValue: String {
            if short.starts(with: "-") {
                return short
            } else {
                return "-" + short
            }
        }

        var longValue: String {
            if long.starts(with: "--") {
                return long
            } else {
                return "--" + long
            }
        }

        func isEqual(to value: String) -> Bool {
            return value == shortValue || value == longValue
        }
    }

    private let arguments = ProcessInfo.processInfo.arguments.dropFirst()

    func getFirstValue(for key: Key) throws -> String {
        guard let keyIndex = arguments.firstIndex(where: key.isEqual) else {
            throw Error.arguments("Please specify \(key.shortValue) or \(key.longValue) argument")
        }
        let valueIndex = keyIndex + 1
        guard arguments.indices.contains(valueIndex) else {
            throw Error.arguments("Please specify \(key.shortValue) or \(key.longValue) argument")
        }

        return arguments[valueIndex]
    }

    func getAllValues(for key: Key) throws -> [String] {
        let keyIndices = arguments.indices.filter { key.isEqual(to: arguments[$0]) }
        let valueIndices = keyIndices.map { $0 + 1 }
        for index in valueIndices {
            guard arguments.indices.contains(index) else {
                throw Error.arguments("Please specify \(key.shortValue) or \(key.longValue) argument")
            }
        }

        return valueIndices.map { arguments[$0] }
    }
}

struct Solver {
    func generateOutput(from input: Input) -> Output {
        fatalError("Not implemented")
    }
}

struct Runner {
    func run() {
        do {
            let arguments = Arguments()
            let io = IO()
            let solver = Solver()
            let inputPaths = try arguments.getAllValues(for: .init(short: "i", long: "input"))
            for path in inputPaths {
                let message = "Solving file at \(path)"
                let separator = Array(repeating: "#", count: message.count).joined()
                print(separator)
                print(message)
                print(separator)
                print("\n")
                let input = try io.readInput(path: path)
                let output = solver.generateOutput(from: input)
                try io.dumpOutput(output, to: path + ".out")
            }
        } catch let error as Error {
            print(error.debugDescription)
        } catch {
            print(error.localizedDescription)
        }
    }
}

Runner().run()
