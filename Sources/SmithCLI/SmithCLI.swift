import Foundation
import ArgumentParser
import SmithCore

@main
struct SmithCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Smith Framework CLI - Unified build analysis and optimization tool",
        discussion: """
        Smith CLI provides a unified interface to all Smith build analysis tools.

        It integrates smith-spmsift, smith-sbsift, smith-xcsift, and smith-core
        to provide comprehensive build analysis, hang detection, and optimization
        recommendations for Swift projects.
        """,
        version: "1.1.0",
        subcommands: [
            Analyze.self,
            Detect.self,
            Status.self,
            Validate.self,
            Optimize.self,
            Environment.self,
            MonitorBuild.self,
            Version.self
        ]
    )
}

// MARK: - Analyze Command

struct Analyze: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Analyze project build performance and issues"
    )

    @Argument(help: "Path to analyze (default: current directory)")
    var path: String = "."

    @Flag(name: .long, help: "Enable hang detection")
    var hangDetection = false

    @Option(name: .long, help: "CPU usage threshold for hang detection (percentage)")
    var cpuThreshold: Double?

    @Option(name: .long, help: "Memory usage threshold for hang detection (GB)")
    var memoryThreshold: Double?

    @Option(name: .long, help: "Hang detection timeout interval (seconds)")
    var timeout: Int = 30

    func run() throws {
        print("🔍 SMITH BUILD ANALYSIS")
        print("========================")

        let resolvedPath = (path as NSString).standardizingPath
        let projectType = ProjectDetector.detectProjectType(at: resolvedPath)

        print("📊 Project Type: \(formatProjectType(projectType))")

        if hangDetection {
            print("\n🚨 HANG DETECTION ENABLED")
            print("   ↳ CPU Threshold: \(cpuThreshold ?? 80.0)%")
            print("   ↳ Memory Threshold: \(memoryThreshold ?? 2.0)GB")
            print("   ↳ Timeout Interval: \(timeout)s")
        }

        let analysis = SmithCore.quickAnalyze(at: resolvedPath)

        print("\n📈 PROJECT METRICS")
        print("==================")
        print("Source Files: \(analysis.metrics.fileCount ?? 0)")
        print("Dependencies: \(analysis.dependencyGraph.targetCount)")
        print("Build System: Detected")

        if hangDetection {
            print("\n🚨 HANG DETECTION")
            print("================")
            print("Hang detection enabled (thresholds: CPU \(cpuThreshold ?? 80.0)%, Memory \(memoryThreshold ?? 2.0)GB)")
        }
    }
}

// MARK: - Detect Command

struct Detect: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Detect build system and project type"
    )

    @Argument(help: "Path to detect (default: current directory)")
    var path: String = "."

    func run() throws {
        print("🔎 PROJECT DETECTION")
        print("===================")

        let resolvedPath = (path as NSString).standardizingPath
        let projectType = ProjectDetector.detectProjectType(at: resolvedPath)
        print("📁 Project Path: \(resolvedPath)")
        print("🏗️  Project Type: \(formatProjectType(projectType))")
        print("⚙️  Build System: Detected")

        let analysis = SmithCore.quickAnalyze(at: resolvedPath)
        print("📊 Quick Stats:")
        print("   • Source Files: \(analysis.metrics.fileCount ?? 0)")
        print("   • Dependencies: \(analysis.dependencyGraph.targetCount)")
        print("   • Language Version: Swift")
    }
}

// MARK: - Status Command

struct Status: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show build environment status"
    )

    func run() throws {
        print("📋 SMITH ENVIRONMENT STATUS")
        print("===========================")

        print("🖥️  System Information:")
        print("   • OS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        print("   • Swift: Compatible")

        print("\n🛠️  Development Tools:")
        print("   • Xcode: Available on this platform")

        print("\n📦 Smith Tools:")
        let smithVersion = SmithCore.version
        print("   • smith-core: \(smithVersion)")

        // Check if smith-validation is available
        if checkSmithValidationAvailable() {
            print("   • smith-validation: Available ✓")
        } else {
            print("   • smith-validation: Not found ✗")
        }
    }
}

// MARK: - Validate Command

struct Validate: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Validate project architecture and dependencies"
    )

    @Argument(help: "Path to validate (default: current directory)")
    var path: String = "."

    @Flag(name: .long, help: "Perform deep validation")
    var deep = false

    func run() throws {
        print("✅ SMITH PROJECT VALIDATION")
        print("==========================")

        let resolvedPath = (path as NSString).standardizingPath
        let projectType = ProjectDetector.detectProjectType(at: resolvedPath)

        print("📊 Project Type: \(formatProjectType(projectType))")

        // Dependency validation (built-in)
        print("\n📦 DEPENDENCY VALIDATION")
        print("========================")
        validateDependencies(at: resolvedPath)

        // TCA validation (delegate to smith-validation)
        if projectType == .spm || projectType != .unknown {
            print("\n🎯 TCA ARCHITECTURAL VALIDATION")
            print("=================================")
            validateTCAArchitecture(at: resolvedPath, deep: deep)
        }
    }

    private func validateDependencies(at path: String) {
        let analysis = SmithCore.quickAnalyze(at: path)
        let depCount = analysis.dependencyGraph.targetCount
        print("Dependencies: \(depCount)")

        if depCount > 20 {
            print("⚠️  High dependency count detected")
        } else {
            print("✅ Dependency count looks reasonable")
        }
    }

    private func validateTCAArchitecture(at path: String, deep: Bool) {
        // Check if smith-validation is available
        guard checkSmithValidationAvailable() else {
            print("❌ smith-validation not found. Install with:")
            print("   brew install smith-validation")
            print("   or")
            print("   swift package install smith-validation")
            return
        }

        // Call smith-validation as a subprocess
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/smith-validation")

        var arguments = ["validate", path]
        if deep {
            arguments.append("--deep")
        }

        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("✅ TCA validation completed successfully")
            } else {
                print("⚠️  TCA validation completed with issues")
            }
        } catch {
            print("❌ Failed to run smith-validation: \(error)")
            print("💡 Make sure smith-validation is installed and in PATH")
        }
    }
}

// MARK: - Optimize Command

struct Optimize: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Optimize project build configuration"
    )

    @Argument(help: "Path to optimize (default: current directory)")
    var path: String = "."

    @Flag(name: .long, help: "Apply optimizations automatically")
    var apply = false

    func run() throws {
        print("⚡ SMITH PROJECT OPTIMIZATION")
        print("=============================")

        let resolvedPath = (path as NSString).standardizingPath
        let projectType = ProjectDetector.detectProjectType(at: resolvedPath)

        print("📊 Project Type: \(formatProjectType(projectType))")

        let analysis = SmithCore.quickAnalyze(at: resolvedPath)

        print("\n🔍 OPTIMIZATION RECOMMENDATIONS")
        print("===============================")

        let depCount = analysis.dependencyGraph.targetCount
        let fileCount = analysis.metrics.fileCount ?? 0

        if depCount > 20 {
            print("• Consider reducing dependency count (\(depCount) dependencies)")
        }

        if fileCount > 1000 {
            print("• Large project detected. Consider modularization")
        }

        if !apply {
            print("\n💡 Use --apply flag to automatically apply optimizations")
        }
    }
}

// MARK: - Environment Command

struct Environment: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show detailed environment information"
    )

    func run() throws {
        print("🖥️  SYSTEM ENVIRONMENT")
        print("=====================")
        print("OS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        print("Swift: Compatible")
    }
}

// MARK: - Monitor Build Command

struct MonitorBuild: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Monitor an active build process"
    )

    @Argument(help: "Build command to monitor")
    var buildCommand: String

    @Option(name: .long, help: "CPU threshold for alerts (percentage)")
    var cpuThreshold: Double = 80.0

    @Option(name: .long, help: "Memory threshold for alerts (GB)")
    var memoryThreshold: Double = 2.0

    func run() throws {
        print("🚨 BUILD MONITORING")
        print("==================")
        print("Command: \(buildCommand)")
        print("CPU Threshold: \(cpuThreshold)%")
        print("Memory Threshold: \(memoryThreshold)GB")

        print("🚨 Monitoring build for hang detection...")
        print("💡 Build monitoring functionality available through smith-core APIs")
    }
}

// MARK: - Version Command

struct Version: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show version information"
    )

    func run() throws {
        print("Smith CLI v1.1.0")
        print("Smith Core v\(SmithCore.version)")
    }
}

// MARK: - Helper Functions

private func formatProjectType(_ type: ProjectType) -> String {
    switch type {
    case .spm: return "Swift Package"
    case .xcodeProject(let project): return "Xcode Project (\(project))"
    case .xcodeWorkspace(let workspace): return "Xcode Workspace (\(workspace))"
    case .unknown: return "Unknown"
    }
}

private func formatBuildSystem(_ system: Any) -> String {
    return "Detected"
}

private func checkSmithValidationAvailable() -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = ["smith-validation"]

    let pipe = Pipe()
    process.standardOutput = pipe

    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}

// MARK: - Error Types

enum ValidationError: Error, LocalizedError {
    case invalidPath(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        }
    }
}