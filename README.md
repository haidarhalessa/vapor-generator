# VaporGen 🚀

A CLI tool to scaffold Vapor components instantly.

## Features
- Generates **Models** (Fluent)
- Generates **Migrations** (Async)
- Generates **Controllers** (Basic CRUD)
- Supports dynamic field types (String, Int, Double, Bool, Date, UUID)
- Auto-detects your project's `Sources` directory

## Installation

### Method 1: Build from Source
```bash
git clone [https://github.com/haidarhalessa/vapor-generator.git](https://github.com/haidarhalessa/vapor-generator.git)
cd VaporGenerator
swift build -c release
cp .build/release/vaporgenerator /usr/local/bin/vgen
```

### Method 2: Mint
If you have Mint installed:
```bash
mint install haidarhalessa/VaporGenerator
```

## Usage
Navigate to your Vapor project root and run:
```bash
vgen <ResourceName> <Field:Type>...
```
### Example
```bash
vgen Product title:string price:double isPublished:bool
```

This will create:
- Sources/[YOUR-VAPOR-PROJECT-NAME]/Models/Product.swift
- Sources/[YOUR-VAPOR-PROJECT-NAME]/Migrations/CreateProduct.swift
- Sources/[YOUR-VAPOR-PROJECT-NAME]/Controllers/ProductController.swift
