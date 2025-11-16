# Smith CLI 🎛️

**Unified interface for Smith Tools build analysis ecosystem**

[![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-mOS%20%7C%20iOS%20%7C%20visionOS-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Smith CLI provides a unified command-line interface for all Smith Tools, offering intelligent project detection, comprehensive build analysis, and seamless tool orchestration.

## 🎯 **Overview**

Smith CLI is the **central hub** of the Smith Tools ecosystem, providing:

- **🔍 Project Detection** - Automatic identification of SPM, Xcode, and mixed projects
- **📊 Comprehensive Analysis** - Full project build assessment
- **🛠️ Tool Orchestration** - Coordinates all Smith Tools automatically
- **📈 Performance Monitoring** - Build timing, bottleneck detection
- **🎯 Issue Resolution** - Smart recommendations for common problems

## 🚀 **Quick Start**

### **Installation**
```bash
# Install via Homebrew
brew install smith-tools/smith/smith-cli

# Or build from source
git clone https://github.com/Smith-Tools/smith-cli
cd smith-cli
swift build
```

### **Basic Usage**
```bash
# Analyze current directory
smith-cli analyze

# Detect project type
smith-cli detect

# Check environment status
smith-cli status

# Validate project configuration
smith-cli validate
```

## 📋 **Commands**

### **🔍 analyze**
Comprehensive project analysis using all available Smith Tools.

```bash
smith-cli analyze [--project <path>] [--format json] [--deep]
```

**Example:**
```bash
$ smith-cli analyze --deep
🔍 SMITH PROJECT ANALYSIS
==========================
📊 Project Type: Xcode Workspace
📋 Packages: 12 packages detected

🛠️ Build Analysis:
✅ smith-spmsift: Package validation passed
✅ smith-xcsift: Build output parsing functional
✅ smith-sbsift: Swift build analysis completed

📈 Performance Metrics:
- Total Targets: 24
- Build Duration: 2.3s
- File Count: 156
- Warnings: 3, Errors: 0
```

### **🎯 detect**
Detect project type and available build systems.

```bash
smith-cli detect [--project <path>] [--verbose]
```

**Example:**
```bash
$ smith-cli detect
🔍 SMITH PROJECT DETECTION
==========================
📊 Project Type: Swift Package Manager
📋 Packages:
   - /path/to/Package.swift

🛠️ Available Build Systems:
   ✅ Xcode
   ✅ Swift
   ✅ spmsift
   ✅ sbsift
   ✅ xcsift

🔧 Smith Tools Availability:
   ✅ smith-spmsift
   ✅ smith-sbsift
   ✅ smith-xcsift
   ✅ smith-cli
```

### **📊 status**
Show current build environment and tool status.

```bash
smith-cli status [--verbose]
```

**Example:**
```bash
$ smith-cli status
📊 SMITH ENVIRONMENT STATUS
==========================
🔧 Smith Core Version: 1.0.0

🛠️ Build Systems:
   ✅ Xcode
   ✅ Swift
   ✅ spmsift
   ✅ sbsift
   ✅ xcsift

🍎 Xcode Version: 15.4
🦀 Swift Version: 6.0.2
```

### **✅ validate**
Validate project configuration and dependencies.

```bash
smith-cli validate [--project <path>] [--deep] [--format json]
```

**Example:**
```bash
$ smith-cli validate --format json
{
  "project": "/path/to/project",
  "project_type": "xcode_workspace",
  "timestamp": "2024-11-16T17:30:00Z",
  "validation": {
    "smith_tools_available": true,
    "package_structure": "valid",
    "dependencies": "resolvable",
    "configuration": "optimal"
  },
  "recommendations": [
    "Consider cleaning DerivedData (2.1GB detected)",
    "Update to latest Swift tools for better performance"
  ]
}
```

### **⚡ optimize**
Analyze and suggest build performance optimizations.

```bash
smith-cli optimize [--project <path>] [--aggressive]
```

### **🌍 environment**
Show detailed environment information.

```bash
smith-cli environment [--json] [--verbose]
```

## 🔧 **Advanced Configuration**

### **Environment Variables**
```bash
# Smith tools installation path
export SMITH_TOOLS_PATH="/opt/smith-tools"

# Default analysis depth
export SMITH_ANALYSIS_DEPTH="normal"  # normal, deep, aggressive

# Output format preference
export SMITH_OUTPUT_FORMAT="json"  # json, compact, toon

# Build timeout (seconds)
export SMITH_BUILD_TIMEOUT=300
```

### **Configuration File**
Create `~/.smith-cli.json`:

```json
{
  "default_analysis": {
    "depth": "normal",
    "format": "json",
    "timeout": 300
  },
  "tools": {
    "smith_spmsift": {
      "enabled": true,
      "path": "/usr/local/bin/smith-spmsift"
    },
    "smith_xcsift": {
      "enabled": true,
      "path": "/usr/local/bin/smith-xcsift"
    },
    "smith_sbsift": {
      "enabled": true,
      "path": "/usr/local/bin/smith-sbsift"
    },
    "xcsift": {
      "enabled": true,
      "path": "/usr/local/bin/xcsift"
    }
  },
  "preferences": {
    "auto_detect": true,
    "parallel_analysis": true,
    "cache_results": true
  }
}
```

## 📊 **Output Formats**

### **JSON Output**
```json
{
  "project": "/Users/developer/MyApp",
  "project_type": "xcode_workspace",
  "analysis": {
    "smith_core_version": "1.0.0",
    "tools_used": ["smith-spmsift", "smith-xcsift"],
    "status": "success",
    "metrics": {
      "targets_count": 15,
      "packages_count": 8,
      "build_duration": 12.3,
      "file_count": 234
    },
    "diagnostics": {
      "errors": 0,
      "warnings": 3,
      "suggestions": 2
    }
  },
  "timestamp": "2024-11-16T17:30:00Z"
}
```

### **Compact Output**
```json
{"project":"MyApp","type":"xcode_workspace","status":"success","tools":4,"targets":15,"duration":12.3,"errors":0,"warnings":3}
```

## 🏗️ **Integration Examples**

### **CI/CD Pipeline**
```bash
#!/bin/bash
set -e

echo "🔍 Running Smith CLI analysis"
ANALYSIS=$(smith-cli analyze --format json)

# Check for errors
ERRORS=$(echo "$ANALYSIS" | jq -r '.analysis.diagnostics.errors')
if [ "$ERRORS" -gt 0 ]; then
    echo "❌ Build analysis failed with $ERRORS errors"
    echo "$ANALYSIS" | jq .
    exit 1
fi

echo "✅ Build analysis passed"
echo "$ANALYSIS" | jq '.analysis.metrics'
```

### **GitHub Actions**
```yaml
name: Smith CLI Analysis

on: [push, pull_request]

jobs:
  smith-analysis:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - name: Install Smith CLI
      run: |
        brew tap smith-tools/smith
        brew install smith-cli

    - name: Run Smith Analysis
      run: |
        smith-cli analyze --format json --project . > smith-analysis.json

    - name: Upload Analysis Results
      uses: actions/upload-artifact@v4
      with:
        name: smith-analysis
        path: smith-analysis.json
```

### **Swift Integration**
```swift
import Foundation

struct SmithCLI {
    static func analyze(projectPath: String) async throws -> AnalysisResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/smith-cli")
        process.arguments = ["analyze", "--project", projectPath, "--format", "json"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return try JSONDecoder().decode(AnalysisResult.self, from: data)
    }
}
```

## 🧪 **Testing**

```bash
# Run all tests
swift test

# Test specific functionality
swift test --filter DetectTests
swift test --filter AnalyzeTests

# Test with real projects
smith-cli analyze --project ./TestProject
```

## 📈 **Performance**

| Project Size | Analysis Time | Memory Usage |
|-------------|---------------|-------------|
| Small (10 files) | ~50ms | ~2MB |
| Medium (100 files) | ~500ms | ~8MB |
| Large (500+ files) | ~2s | ~25MB |
| Complex (1000+ files) | ~5s | ~50MB |

## 🔄 **Migration from Manual Tools**

**Before:**
```bash
# Manual tool orchestration
smith-spmsift validate .
smith-spmsift analyze .
echo "BUILD SUCCEEDED" | xcsift --warnings
swift build 2>&1 | smith-sbsift parse
```

**After:**
```bash
# Single command with auto-detection
smith-cli analyze --deep
```

## 🤝 **Contributing**

**Development Setup:**
```bash
git clone https://github.com/Smith-Tools/smith-cli
cd smith-cli
swift build
swift test
```

**Project Structure:**
```
smith-cli/
├── Sources/
│   └── SmithCLI/
│       ├── SmithCLI.swift          # Main entry point
│       ├── Commands/               # CLI command implementations
│       ├── Analysis/              # Analysis orchestration
│       ├── Detection/              # Project type detection
│       └── Configuration/           # Configuration management
└── Tests/
    └── SmithCLITests/
        ├── CommandTests/
        ├── AnalysisTests/
        └── IntegrationTests/
```

## 📄 **License**

Smith CLI is available under the [MIT License](LICENSE).

## 🔗 **Related Projects**

- **[Smith Core](https://github.com/Smith-Tools/smith-core)** - Shared framework
- **[XCSift](https://github.com/Smith-Tools/xcsift)** - Xcode build analysis
- **[Smith SPSift](https://github.com/Smith-Tools/smith-spmsift)** - SPM analysis
- **[Smith SBSift](https://github.com/Smith-Tools/smith-sbsift)** - Swift build analysis
- **[Smith Framework](https://github.com/Smith-Tools/smith-framework)** - Development patterns

---

**Smith CLI - Unified interface for context-efficient Swift build analysis**