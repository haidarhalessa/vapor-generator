//
//  ResourceField.swift
//  VaporGenerator
//
//  Created by haidaralessa on 01/01/2026.
//

import Foundation

struct ResourceField {
    let name: String
    let type: String
    
    var swiftType: String {
        switch type.lowercased() {
            case "int": return "Int"
            case "double": return "Double"
            case "bool": return "Bool"
            case "date": return "Date"
            case "uuid": return "UUID"
            default: return "String"
        }
    }
    
    var fluentType: String {
        switch type.lowercased() {
            case "int": return ".int"
            case "double": return ".double"
            case "bool": return ".bool"
            case "date": return ".datetime"
            case "uuid": return ".uuid"
            default: return ".string"
        }
    }
    
    static func from(_ input: String) -> ResourceField {
        let parts = input.split(separator: ":")
        let name = String(parts[0])
        let type = parts.count > 1 ? String(parts[1]) : "string"
        return ResourceField(name: name, type: type)
    }
}
