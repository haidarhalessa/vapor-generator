// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import ArgumentParser

@main
struct VaporGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A CLI tool to generate Vapor boilerplate components."
    )
    
    @Argument(help: "The name of the resource (e.g., Product)")
    var name: String
    
    @Argument(help: "Fields in format name:type (e.g. title:string price:int)")
    var rawFields: [String] = []
    
    func run() throws {
        let resourceName = name.capitalized
        print("🚀 Generating files for resource: \(resourceName)...")
        
        let fields = rawFields.map { ResourceField.from($0) }
        
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let targetPath = try findTargetDirectory(fileManager: fileManager, currentPath: currentPath)
                
        print("🚀 Generating \(resourceName) with \(fields.count) fields...")
        
        try createModel(name: resourceName, fields: fields, path: "\(targetPath)/Models")
        try createMigration(name: resourceName, fields: fields, path: "\(targetPath)/Migrations")
        try createController(name: resourceName, path: "\(targetPath)/Controllers")
        
        print("✅ Done! Don't forget to register the Migration and Controller in configure.swift.")
    }
    
    private func findTargetDirectory(fileManager: FileManager, currentPath: String) throws -> String {
        let sourcesPath = "\(currentPath)/Sources"
        
        guard fileManager.fileExists(atPath: sourcesPath) else {
            throw ValidationError("Could not find 'Sources' directory. Are your this from the roort of your project?")
        }
        
        let contents = try fileManager.contentsOfDirectory(atPath: sourcesPath)
        let directories = contents.filter { content in
            guard !content.hasPrefix(".") else { return false }
            var isDir: ObjCBool = false
            return fileManager.fileExists(atPath: "\(sourcesPath)/\(content)", isDirectory: &isDir) && isDir.boolValue
        }
        
        // Strategy 1: If only one directory exsits, that's our project!
        if directories.count == 1, let onlyDir = directories.first {
            return "\(sourcesPath)/\(onlyDir)"
        }
        
        // Strategy 2: If multiple, find the one containing 'configure.swift' (Vapor standard)
        for dir in directories {
            let configPath = "\(sourcesPath)/\(dir)/configure.swift"
            if fileManager.fileExists(atPath: configPath) {
                return "\(sourcesPath)/\(dir)"
            }
        }
        
        // Strategy 3: Fallback (Try 'App' if it exists among others)
        if directories.contains("App") {
            return "\(sourcesPath)/App"
        }
        
        throw ValidationError("Could not auto-detect the project folder in Sources/. Found \(directories)")
    }
    
    func createModel(name: String, fields: [ResourceField], path: String) throws {
        
        let propertyLines = fields.map { field in
            """
                @Field(key: "\(field.name)")
                var \(field.name): \(field.swiftType)
            """
        }.joined(separator: "\n\n")
        
        let content = """
        import Fluent
        import Vapor

        final class \(name): Model, Content, @unchecked Sendable {
            static let schema = "\(name.lowercased())s"
            
            @ID(key: .id)
            var id: UUID?
            
        \(propertyLines)
        
            init() { }
        
            init(id: UUID? = nil, \(fields.map { "\($0.name): \($0.swiftType)" }.joined(separator: ", "))) {
                self.id = id
                \(fields.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n       "))
            }
        }
        """
        
        try write(content: content, to: path, filename: "\(name).swift")
    }
    
    func createMigration(name: String, fields: [ResourceField], path: String) throws {
        
        let fieldLines = fields.map { field in
                "            .field(\"\(field.name)\", \(field.fluentType), .required)"
            }.joined(separator: "\n")
        
        let content = """
        import Fluent
        
        struct Create\(name): AsyncMigration {
            func prepare(on database: any Database) async throws {
                try await database.schema("\(name.lowercased())s")
                    .id()
        \(fieldLines)
                    .create()
            }
        
            func revert(on database: any Database) async throws {
                try await database.schema("\(name.lowercased())s").delete()
            }
        }
        """
        
        try write(content: content, to: path, filename: "Create\(name).swift")
    }
    
    func createController(name: String, path: String) throws {
        let content = """
        import Fluent
        import Vapor
        
        struct \(name)Controller: RouteCollection {
            func boot(routes: any RoutesBuilder) throws {
                let \(name.lowercased())s = routes.grouped("\(name.lowercased())s")
                \(name.lowercased())s.get(use: index)
                \(name.lowercased())s.post(use: create)
            }
        
            func index(req: Request) async throws -> [\(name)] {
                try await \(name).query(on: req.db).all()
            }
        
            func create(req: Request) async throws -> \(name) {
                let input = try req.content.decode(\(name).self)
                try await input.save(on: req.db)
                return input
            }
        }
        """
        
        try write(content: content, to: path, filename: "\(name)Controller.swift")
    }
    
    func write(content: String, to directory: String, filename: String) throws {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: directory) {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        
        let filePath = "\(directory)/\(filename)"
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
        print("     📄 Created: \(filename)")
    }
}
    
