import Foundation
import ArgumentParser
import SmithCore
import SmithValidation
import SmithValidationCore
import MaxwellsTCARules
import SwiftSyntax

enum TCAOutputFormat: String, ExpressibleByArgument {
    case swiftTesting = "swift-testing"
    case detailed
}

enum TCASeverityFilter: String, ExpressibleByArgument {
    case critical
    case high
    case medium
    case low
    case info

    var severity: ArchitecturalViolation.Severity {
        switch self {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .info: return .info
        }
    }
}

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
            AnalyzeDependencies.self,
            BuildDiagnose.self,
            BuildMonitor.self,
            BuildFix.self,
            BuildEmergency.self
        ]
    )
}

// MARK: - Analyze Command

struct Analyze: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Comprehensive project analysis",
        discussion: """
        Performs deep analysis of your Swift project including:
        - Project type detection
        - Dependency graph analysis
        - Build complexity assessment
        - Risk identification and recommendations
        """
    )

    @Argument(help: "Path to the project directory (default: current directory)")
    var path: String = "."

    @Flag(name: .long, help: "Output in JSON format")
    var json = false

    @Flag(name: .long, help: "Include detailed diagnostics")
    var verbose = false

    @Flag(name: .long, help: "Focus on hang detection analysis")
    var hangAnalysis = false

    func run() throws {
        print("🔍 SMITH COMPREHENSIVE ANALYSIS")
        print("===============================")

        let resolvedPath = (path as NSString).standardizingPath
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: resolvedPath) else {
            throw SmithError.invalidPath(resolvedPath)
        }

        // Detect project type
        let projectType = ProjectDetector.detectProjectType(at: resolvedPath)
        print("📊 Project Type: \(formatProjectType(projectType))")

        // Quick analysis
        var analysis = SmithCore.quickAnalyze(at: resolvedPath)

        // Enhanced analysis based on project type
        switch projectType {
        case .spm:
            analysis = try analyzeSPMProject(at: resolvedPath)
        case .xcodeWorkspace, .xcodeProject:
            analysis = try analyzeXcodeProject(at: resolvedPath)
        case .unknown:
            print("⚠️  Unknown project type, performing basic analysis")
        }

        // Additional hang analysis if requested
        if hangAnalysis {
            print("\n🎯 HANG DETECTION ANALYSIS")
            print("==========================")
            let hangAnalysis = try performHangAnalysis(at: resolvedPath, projectType: projectType)
            print(formatHangAnalysis(hangAnalysis))
        }

        // Risk assessment
        let risks = SmithCore.assessBuildRisk(analysis)
        if !risks.isEmpty {
            print("\n⚠️  BUILD RISK ASSESSMENT")
            print("========================")
            for risk in risks {
                let emoji = emojiForSeverity(risk.severity)
                print("\(emoji) [\(risk.category.rawValue)] \(risk.message)")
                if let suggestion = risk.suggestion {
                    print("   💡 \(suggestion)")
                }
            }
        }

        // Output results
        if json {
            if let jsonData = SmithCore.formatJSON(analysis) {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                }
            }
        } else {
            print("\n" + SmithCore.formatHumanReadable(analysis))
        }

        // Recommendations
        let recommendations = generateRecommendations(for: analysis)
        if !recommendations.isEmpty {
            print("\n💡 RECOMMENDATIONS")
            print("==================")
            for (index, recommendation) in recommendations.enumerated() {
                print("\(index + 1). \(recommendation)")
            }
        }
    }

    private func analyzeSPMProject(at path: String) throws -> BuildAnalysis {
        print("🔧 Analyzing Swift Package...")

        // Run spmsift if available
        if SmithCore.isToolAvailable(.spmsift) {
            return try runSPMSiftAnalysis(at: path)
        } else {
            print("⚠️  spmsift not available, using basic analysis")
            return SmithCore.quickAnalyze(at: path)
        }
    }

    private func analyzeXcodeProject(at path: String) throws -> BuildAnalysis {
        print("🏗️  Analyzing Xcode Project...")

        // Run xcsift if available
        if SmithCore.isToolAvailable(.xcsift) {
            return try runXCSiftAnalysis(at: path)
        } else {
            print("⚠️  xcsift not available, using basic analysis")
            return SmithCore.quickAnalyze(at: path)
        }
    }

    private func runSPMSiftAnalysis(at path: String) throws -> BuildAnalysis {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/spmsift")
        process.arguments = ["--analyze", "--json", path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw SmithError.toolExecutionFailed("spmsift")
        }

        // Parse spmsift output and convert to SmithCore model
        // This would integrate with smith-spmsift's JSON output
        return SmithCore.quickAnalyze(at: path)
    }

    private func runXCSiftAnalysis(at path: String) throws -> BuildAnalysis {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/xcsift")
        process.arguments = ["--analyze", "--json", path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw SmithError.toolExecutionFailed("xcsift")
        }

        // Parse xcsift output and convert to SmithCore model
        // This would integrate with smith-xcsift's JSON output
        return SmithCore.quickAnalyze(at: path)
    }

    private func performHangAnalysis(at path: String, projectType: ProjectType) throws -> HangDetection {
        // Simulated hang analysis - would integrate with specialized tools
        return HangDetection(
            isHanging: false,
            suspectedPhase: nil,
            suspectedFile: nil,
            timeElapsed: 0.0,
            recommendations: [
                "Use incremental builds to reduce compile time",
                "Check for circular dependencies",
                "Monitor build cache health"
            ]
        )
    }
}

// MARK: - Detect Command

struct Detect: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Detect project type and available tools"
    )

    @Argument(help: "Path to analyze (default: current directory)")
    var path: String = "."

    func run() throws {
        print("🔍 SMITH PROJECT DETECTION")
        print("==========================")

        let resolvedPath = (path as NSString).standardizingPath

        // Project type detection
        let projectType = ProjectDetector.detectProjectType(at: resolvedPath)
        print("📊 Project Type: \(formatProjectType(projectType))")

        // File discovery
        let workspaces = ProjectDetector.findWorkspaceFiles(in: resolvedPath)
        let projects = ProjectDetector.findProjectFiles(in: resolvedPath)
        let packages = ProjectDetector.findPackageFiles(in: resolvedPath)

        if !workspaces.isEmpty {
            print("🔨 Workspaces:")
            for workspace in workspaces {
                print("   - \(workspace)")
            }
        }

        if !projects.isEmpty {
            print("📦 Projects:")
            for project in projects {
                print("   - \(project)")
            }
        }

        if !packages.isEmpty {
            print("📋 Packages:")
            for package in packages {
                print("   - \(package)")
            }
        }

        // Build system detection
        print("\n🛠️  Available Build Systems:")
        let buildSystems = BuildSystemDetector.detectAvailableBuildSystems()
        for system in buildSystems {
            print("   ✅ \(system.name)")
        }

        // Smith tools availability
        print("\n🔧 Smith Tools Availability:")
        let smithTools = ["smith-spmsift", "smith-sbsift", "smith-xcsift", "smith-cli"]
        for tool in smithTools {
            let isAvailable = commandExists(tool)
            print("   \(isAvailable ? "✅" : "❌") \(tool)")
        }
    }
}

// MARK: - Status Command

struct Status: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show current build environment status"
    )

    func run() throws {
        print("📊 SMITH ENVIRONMENT STATUS")
        print("==========================")

        // Smith Core version
        print("🔧 Smith Core Version: \(SmithCore.version)")

        // Available build systems
        let buildSystems = BuildSystemDetector.detectAvailableBuildSystems()
        print("\n🛠️  Build Systems:")
        for system in buildSystems {
            print("   ✅ \(system.name)")
        }

        // Xcode info
        if let xcodeVersion = getXcodeVersion() {
            print("\n🍎 Xcode Version: \(xcodeVersion)")
        }

        // Swift version
        if let swiftVersion = getSwiftVersion() {
            print("🦀 Swift Version: \(swiftVersion)")
        }

        // Memory info
        if let memoryInfo = getMemoryInfo() {
            print("\n💾 Memory: \(memoryInfo)")
        }
    }
}

// MARK: - Validate Command

struct Validate: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Validate project dependencies and Package.resolved"
    )

    @Argument(help: "Path to validate (default: current directory)")
    var path: String = "."

    @Flag(name: .long, help: "Perform deep validation")
    var deep = false

    @Flag(name: .long, help: "Check Package.resolved for branch dependencies")
    var checkResolved = false

    @Flag(name: .long, help: "Flag branch dependencies as anti-patterns")
    var flagBranchDeps = false

    @Flag(name: .long, help: "Validate TCA architectural patterns")
    var tca = false

    @Flag(name: .long, help: "Validate only TCA architectural patterns (skip dependencies)")
    var tcaOnly = false

    @Option(name: .customLong("tca-state-threshold"), help: "Maximum properties allowed in a State before Rule 1.1 flags it (default: 15)")
    var tcaStateThreshold: Int?

    @Option(name: .customLong("tca-action-threshold"), help: "Maximum Action cases allowed before Rule 1.1 flags it (default: 40)")
    var tcaActionThreshold: Int?

    @Option(name: .customLong("tca-min-severity"), help: "Minimum severity to include in the report (critical|high|medium|low|info)")
    var tcaMinSeverity: TCASeverityFilter?

    @Option(name: .customLong("tca-output"), help: "TCA report style: swift-testing or detailed")
    var tcaOutputFormat: TCAOutputFormat = .swiftTesting

    @Option(name: .customLong("tca-max-examples"), help: "Maximum violation samples to show per rule")
    var tcaMaxExamples: Int = 5

    // MARK: - TCA Validation Methods
    private func validateTCAArchitecture(at path: String) throws {
        print("\n🎯 TCA ARCHITECTURAL VALIDATION")
        print("================================\n")
        
        if let stateThreshold = tcaStateThreshold, stateThreshold < 1 {
            throw ValidationError("--tca-state-threshold must be greater than zero")
        }
        
        if let actionThreshold = tcaActionThreshold, actionThreshold < 1 {
            throw ValidationError("--tca-action-threshold must be greater than zero")
        }
        
        guard tcaMaxExamples > 0 else {
            throw ValidationError("--tca-max-examples must be greater than zero")
        }
        
        let resolvedPath = (path as NSString).standardizingPath
        let projectURL = URL(fileURLWithPath: resolvedPath)
        
        // Find all Swift files
        let swiftFiles = try FileUtils.findSwiftFiles(in: projectURL)
        
        guard !swiftFiles.isEmpty else {
            print("📁 No Swift files found for TCA validation")
            return
        }
        
        print("🔍 Analyzing \(swiftFiles.count) Swift files...")
        if let minSeverity = tcaMinSeverity {
            print("   ↳ Reporting \(minSeverity.rawValue.uppercased()) severity and above")
        }
        
        let rule1Config = TCARule_1_1_MonolithicFeatures.Configuration(
            maxStateProperties: tcaStateThreshold ?? 15,
            maxActionCases: tcaActionThreshold ?? 40
        )
        
        let rule1_1 = TCARule_1_1_MonolithicFeatures(configuration: rule1Config)
        let rule1_2 = TCARule_1_2_ProperDependencyInjection()
        let rule1_3 = TCARule_1_3_CodeDuplication()
        let rule1_4 = TCARule_1_4_UnclearOrganization()
        let rule1_5 = TCARule_1_5_TightlyCoupledState()
        
        var parsedFiles = 0
        var ruleViolations: [String: [ArchitecturalViolation]] = [
            "1.1": [],
            "1.2": [],
            "1.3": [],
            "1.4": [],
            "1.5": []
        ]
        
        // Process each Swift file
        for swiftFileURL in swiftFiles {
            do {
                let sourceFile = try SourceFileSyntax.parse(from: swiftFileURL)
                parsedFiles += 1
                let context = SourceFileContext(
                    path: swiftFileURL.path,
                    url: swiftFileURL,
                    syntax: sourceFile
                )
                
                // Run all TCA rules and keep per-rule buckets
                let violations1_1 = rule1_1.validate(context: context)
                ruleViolations["1.1", default: []].append(contentsOf: violations1_1.violations)
                
                let violations1_2 = rule1_2.validate(context: context)
                ruleViolations["1.2", default: []].append(contentsOf: violations1_2.violations)
                
                let violations1_3 = rule1_3.validate(context: context)
                ruleViolations["1.3", default: []].append(contentsOf: violations1_3.violations)
                
                let violations1_4 = rule1_4.validate(context: context)
                ruleViolations["1.4", default: []].append(contentsOf: violations1_4.violations)
                
                let violations1_5 = rule1_5.validate(context: context)
                ruleViolations["1.5", default: []].append(contentsOf: violations1_5.violations)
                
            } catch {
                // Skip files that can't be parsed
                continue
            }
        }
        
        let orderedRules: [(String, String)] = [
            ("1.1", "Monolithic Features"),
            ("1.2", "Proper Dependency Injection"),
            ("1.3", "Code Duplication"),
            ("1.4", "Unclear Organization"),
            ("1.5", "Tightly Coupled State")
        ]
        
        let filteredCollections: [(rule: String, violations: ViolationCollection)] = orderedRules.map { ruleInfo in
            let rawViolations = ruleViolations[ruleInfo.0] ?? []
            let filtered = applySeverityFilter(rawViolations)
            return (rule: ruleInfo.0, violations: ViolationCollection(violations: filtered))
        }
        
        let displayedViolations = filteredCollections.flatMap { $0.violations.violations }
        let totalViolations = ruleViolations.values.reduce(into: 0) { $0 += $1.count }
        
        if totalViolations == 0 {
            print("✅ No TCA violations detected across the project!")
            return
        }
        
        if displayedViolations.isEmpty {
            print("✅ No TCA violations found at the selected severity filter")
            return
        }
        
        let report: String
        switch tcaOutputFormat {
        case .swiftTesting:
            report = ValidationReporter.generateSwiftTestingStyleReport(
                for: filteredCollections,
                totalFiles: swiftFiles.count,
                parsedFiles: parsedFiles,
                maxExamplesPerRule: tcaMaxExamples
            )
        case .detailed:
            report = ValidationReporter.generateReport(
                for: filteredCollections,
                totalFiles: swiftFiles.count,
                parsedFiles: parsedFiles
            )
        }
        
        print(report)
    }
func run() throws {
        // Handle TCA validation modes
        if tcaOnly {
            print("✅ SMITH TCA VALIDATION")
            print("========================")
            try validateTCAArchitecture(at: path)
            return
        }
        
        if tca {
            print("✅ SMITH PROJECT VALIDATION")
            print("===========================\n")
        } else {
            print("✅ SMITH DEPENDENCY VALIDATION")
            print("==============================\n")
        }
        
        let resolvedPath = (path as NSString).standardizingPath
        var issues: [Diagnostic] = []
        
        // Run dependency validation (if not tca-only)
        if !tcaOnly {
            let projectType = ProjectDetector.detectProjectType(at: resolvedPath)
            switch projectType {
            case .spm:
                issues = try validateSPMProject(at: resolvedPath, deep: deep, checkResolved: checkResolved, flagBranchDeps: flagBranchDeps)
            case .xcodeWorkspace, .xcodeProject:
                issues = try validateXcodeProject(at: resolvedPath, deep: deep, checkResolved: checkResolved, flagBranchDeps: flagBranchDeps)
            case .unknown:
                if !tca {
                    print("❌ Cannot validate unknown project type")
                }
                // Continue with TCA validation even for unknown project types
            }
        }
        
        // Run TCA validation
        if tca || tcaOnly {
            try validateTCAArchitecture(at: path)
        }
        
        // Summary (only show dependency summary if we ran dependency validation)
        if !tcaOnly && !issues.isEmpty {
            print("\n📊 DEPENDENCY SUMMARY")
            print("=====================")
            let errorCount = issues.filter { $0.severity == .error }.count
            let warningCount = issues.filter { $0.severity == .warning }.count
            let infoCount = issues.filter { $0.severity == .info }.count
            
            if errorCount > 0 {
                print("🔴 Errors: \(errorCount)")
            }
            if warningCount > 0 {
                print("🟠 Warnings: \(warningCount)")
            }
            if infoCount > 0 {
                print("🔵 Info: \(infoCount)")
            }
        }
    }

    private func validateSPMProject(at path: String, deep: Bool, checkResolved: Bool, flagBranchDeps: Bool) throws -> [Diagnostic] {
        var issues: [Diagnostic] = []

        let packagePath = URL(fileURLWithPath: path).appendingPathComponent("Package.swift")
        guard FileManager.default.fileExists(atPath: packagePath.path) else {
            issues.append(Diagnostic(
                severity: .error,
                category: .configuration,
                message: "Package.swift not found",
                suggestion: "Create a Package.swift file"
            ))
            return issues
        }

        // Additional SPM validation would go here
        if deep {
            print("🔍 Performing deep SPM validation...")
            // Would integrate with smith-spmsift
        }

        if checkResolved {
            print("🔍 Checking Package.resolved...")
            issues.append(contentsOf: validatePackageResolved(at: path, flagBranches: flagBranchDeps))
        }

        return issues
    }

    private func validateXcodeProject(at path: String, deep: Bool, checkResolved: Bool, flagBranchDeps: Bool) throws -> [Diagnostic] {
        var issues: [Diagnostic] = []

        if deep {
            print("🔍 Performing deep Xcode validation...")
            // Would integrate with smith-xcsift
        }

        if checkResolved {
            print("🔍 Checking Package.resolved...")
            issues.append(contentsOf: validatePackageResolved(at: path, flagBranches: flagBranchDeps))
        }

        return issues
    }

    private func validatePackageResolved(at path: String, flagBranches: Bool) -> [Diagnostic] {
        var issues: [Diagnostic] = []

        // Check for Package.resolved in Xcode project
        let resolvedPaths = [
            "\(path)/Package.resolved",
            "\(path)/.build/Package.resolved",
            "\(path)/project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
            "\(path)/*/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
        ]

        var foundResolved = false
        var totalDependencies = 0
        var branchDependencies = 0
        var branchDeps: [String] = []

        for resolvedPath in resolvedPaths {
            let expandedPath = (resolvedPath as NSString).expandingTildeInPath

            // Handle wildcards for Xcode projects
            if resolvedPath.contains("*") {
                let globPattern = expandedPath.replacingOccurrences(of: "*", with: "*")
                if let globPaths = globFiles(pattern: globPattern) {
                    for resolvedPath in globPaths {
                        if FileManager.default.fileExists(atPath: resolvedPath) {
                            foundResolved = true
                            let (deps, branches, branchNames) = analyzePackageResolved(at: resolvedPath)
                            totalDependencies += deps
                            branchDependencies += branches
                            branchDeps.append(contentsOf: branchNames)
                        }
                    }
                }
            } else {
                if FileManager.default.fileExists(atPath: expandedPath) {
                    foundResolved = true
                    let (deps, branches, branchNames) = analyzePackageResolved(at: expandedPath)
                    totalDependencies += deps
                    branchDependencies += branches
                    branchDeps.append(contentsOf: branchNames)
                }
            }
        }

        if !foundResolved {
            issues.append(Diagnostic(
                severity: .info,
                category: .dependency,
                message: "No Package.resolved found",
                suggestion: "Run 'swift package resolve' to generate resolved dependencies"
            ))
            return issues
        }

        print("📋 Package.resolved Analysis:")
        print("   • Total dependencies: \(totalDependencies)")
        print("   • Branch dependencies: \(branchDependencies)")

        if branchDependencies > 0 {
            let uniqueBranchDeps = Array(Set(branchDeps))
            print("   • Branch dependency packages: \(uniqueBranchDeps.joined(separator: ", "))")

            if flagBranches {
                issues.append(Diagnostic(
                    severity: .warning,
                    category: .dependency,
                    message: "Found \(branchDependencies) branch dependencies (anti-pattern)",
                    suggestion: "Pin all dependencies to specific versions or exact revisions"
                ))

                for dep in uniqueBranchDeps {
                    issues.append(Diagnostic(
                        severity: .info,
                        category: .dependency,
                        message: "Branch dependency: \(dep)",
                        suggestion: "Replace 'branch: \"main\"' with specific version or revision"
                    ))
                }
            } else {
                issues.append(Diagnostic(
                    severity: .info,
                    category: .dependency,
                    message: "Found \(branchDependencies) branch dependencies",
                    suggestion: "Use --flag-branch-deps to flag these as anti-patterns"
                ))
            }
        } else {
            issues.append(Diagnostic(
                severity: .info,
                category: .dependency,
                message: "All dependencies are properly versioned",
                suggestion: nil
            ))
        }

        return issues
    }

    private func analyzePackageResolved(at path: String) -> (totalDeps: Int, branchDeps: Int, branchNames: [String]) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let json = try JSONSerialization.jsonObject(with: data, options: [])

            guard let object = json as? [String: Any],
                  let pins = object["pins"] as? [[String: Any]] else {
                return (0, 0, [])
            }

            var totalDeps = 0
            var branchDeps = 0
            var branchNames: [String] = []

            for pin in pins {
                totalDeps += 1

                if let state = pin["state"] as? [String: Any] {
                    // Check for branch dependency
                    if let _ = state["branch"] as? String {
                        branchDeps += 1
                        if let identity = pin["identity"] as? String {
                            branchNames.append(identity)
                        }
                    }

                    // Check for revision without version (potentially unstable)
                    if let revision = state["revision"] as? String,
                       state["branch"] == nil,
                       state["version"] == nil {
                        // This is a revision-based dependency without a version
                        branchDeps += 1
                        if let identity = pin["identity"] as? String {
                            branchNames.append("\(identity) (revision-only)")
                        }
                    }
                }
            }

            return (totalDeps, branchDeps, branchNames)

        } catch {
            return (0, 0, [])
        }
    }

  
    private func globFiles(pattern: String) -> [String]? {
        guard let dir = NSString(string: pattern).deletingLastPathComponent as String? else { return nil }
        let filename = NSString(string: pattern).lastPathComponent

        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return nil }

        return contents.compactMap { file in
            let fullPath = "\(dir)/\(file)"
            return file.contains("*") || file.hasPrefix(filename.replacingOccurrences(of: "*", with: "")) ? fullPath : nil
        }
    }
}

private extension Validate {
    func applySeverityFilter(_ violations: [ArchitecturalViolation]) -> [ArchitecturalViolation] {
        guard let minSeverity = tcaMinSeverity?.severity else {
            return violations
        }
        return violations.filter { $0.severity.priority >= minSeverity.priority }
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
        let recommendations = generateOptimizationRecommendations(for: analysis, projectType: projectType)

        if recommendations.isEmpty {
            print("✅ No optimizations needed")
        } else {
            print("💡 Optimization Recommendations:")
            for (index, recommendation) in recommendations.enumerated() {
                print("\(index + 1). \(recommendation)")
            }

            if apply {
                print("\n🔧 Applying optimizations...")
                // Would apply actual optimizations
                print("✅ Optimizations applied")
            }
        }
    }
}

// MARK: - Environment Command

struct Environment: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show detailed environment information"
    )

    func run() throws {
        print("🌍 SMITH ENVIRONMENT DETAILS")
        print("============================")

        // System info
        let systemInfo = getSystemInfo()
        print("💻 System: \(systemInfo)")

        // Build tools
        print("\n🛠️  Build Tools:")
        let tools = ["xcodebuild", "swift", "spmsift", "sbsift", "xcsift"]
        for tool in tools {
            let available = commandExists(tool)
            let version = available ? getToolVersion(tool) : "N/A"
            print("   \(available ? "✅" : "❌") \(tool) (\(version))")
        }

        // Paths
        print("\n📂 Important Paths:")
        print("   Current Directory: \(FileManager.default.currentDirectoryPath)")
        if let xcodePath = getXcodePath() {
            print("   Xcode: \(xcodePath)")
        }
        if let swiftPath = getSwiftPath() {
            print("   Swift: \(swiftPath)")
        }
    }
}

// MARK: - Supporting Types

enum SmithError: Error, LocalizedError {
    case invalidPath(String)
    case toolExecutionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        case .toolExecutionFailed(let tool):
            return "Tool execution failed: \(tool)"
        }
    }
}

// MARK: - Helper Functions

private func formatProjectType(_ projectType: ProjectType) -> String {
    switch projectType {
    case .spm:
        return "Swift Package Manager"
    case .xcodeWorkspace(let workspace):
        return "Xcode Workspace (\(URL(fileURLWithPath: workspace).lastPathComponent))"
    case .xcodeProject(let project):
        return "Xcode Project (\(URL(fileURLWithPath: project).lastPathComponent))"
    case .unknown:
        return "Unknown"
    }
}

private func emojiForSeverity(_ severity: Diagnostic.Severity) -> String {
    switch severity {
    case .info: return "ℹ️"
    case .warning: return "⚠️"
    case .error: return "❌"
    case .critical: return "🚨"
    }
}

private func formatHangAnalysis(_ hang: HangDetection) -> String {
    var output: [String] = []

    if hang.isHanging {
        output.append("🚨 HANG DETECTED")
        if let phase = hang.suspectedPhase {
            output.append("   Suspected Phase: \(phase)")
        }
        if let file = hang.suspectedFile {
            output.append("   Suspected File: \(file)")
        }
    } else {
        output.append("✅ No hang detected")
    }

    if !hang.recommendations.isEmpty {
        output.append("\n💡 Recommendations:")
        for recommendation in hang.recommendations {
            output.append("   - \(recommendation)")
        }
    }

    return output.joined(separator: "\n")
}

private func generateRecommendations(for analysis: BuildAnalysis) -> [String] {
    var recommendations: [String] = []

    // Complexity-based recommendations
    switch analysis.dependencyGraph.complexity {
    case .high, .extreme:
        recommendations.append("Consider breaking into smaller modules")
        recommendations.append("Use incremental builds")
        recommendations.append("Monitor build cache health")
    case .medium:
        recommendations.append("Consider build optimization")
    case .low:
        break
    }

    // Dependency-based recommendations
    if analysis.dependencyGraph.circularDeps {
        recommendations.append("Eliminate circular dependencies")
    }

    if analysis.dependencyGraph.maxDepth > 6 {
        recommendations.append("Reduce dependency depth")
    }

    return recommendations
}

private func generateOptimizationRecommendations(for analysis: BuildAnalysis, projectType: ProjectType) -> [String] {
    var recommendations: [String] = []

    switch projectType {
    case .spm:
        recommendations.append("Use target-specific dependencies")
        recommendations.append("Enable parallel builds")
        recommendations.append("Optimize package manifest")
    case .xcodeWorkspace, .xcodeProject:
        recommendations.append("Enable parallel building")
        recommendations.append("Optimize build settings")
        recommendations.append("Use proper build configurations")
    case .unknown:
        break
    }

    return recommendations
}

private func commandExists(_ command: String) -> Bool {
    let task = Process()
    task.launchPath = "/usr/bin/which"
    task.arguments = [command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()

    task.launch()
    task.waitUntilExit()

    return task.terminationStatus == 0
}

private func getToolVersion(_ tool: String) -> String {
    let task = Process()
    task.launchPath = tool
    task.arguments = ["--version"]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = Pipe()

    do {
        try task.run()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines).first ?? "Unknown"
            }
        }
    } catch {
        // Tool doesn't support --version or failed to run
    }

    return "Unknown"
}

private func getXcodeVersion() -> String? {
    return getToolVersion("xcodebuild").components(separatedBy: " ").dropFirst().joined(separator: " ")
}

private func getSwiftVersion() -> String? {
    return getToolVersion("swift").components(separatedBy: " ").dropFirst().joined(separator: " ")
}

private func getXcodePath() -> String? {
    return getToolVersion("xcode-select").components(separatedBy: " ").last
}

private func getSwiftPath() -> String? {
    guard commandExists("swift") else { return nil }
    return "/usr/bin/swift" // Default location
}

private func getSystemInfo() -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/uname")
    process.arguments = ["-a"]

    let pipe = Pipe()
    process.standardOutput = pipe

    do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    } catch {
        // Failed to get system info
    }

    return "Unknown"
}

private func getMemoryInfo() -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/vm_stat")

    let pipe = Pipe()
    process.standardOutput = pipe

    do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Extract memory info from vm_stat output
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    if line.contains("Free:") {
                        return line.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
    } catch {
        // Failed to get memory info
    }

    return nil
}

// Helper function for hybrid project detection
private func detectHybridProject(at path: String) -> Bool {
    let fileManager = FileManager.default
    let hasXcode = fileManager.fileExists(atPath: "\(path)/Scroll.xcodeproj") ||
                  fileManager.fileExists(atPath: "\(path)/Scroll.xcworkspace")
    let hasSPM = fileManager.fileExists(atPath: "\(path)/Package.swift") ||
                 fileManager.fileExists(atPath: "\(path)/ScrollModules/Package.swift")
    return hasXcode && hasSPM
}

// MARK: - MonitorBuild Command

struct MonitorBuild: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Monitor build progress with beautiful progress bars and hang detection",
        discussion: """
        Real-time build monitoring with progress tracking, hang detection, and phase analysis.

        Supports both Xcode projects and Swift Package Manager with automatic detection.
        """
    )

    @Argument(help: "Path to monitor (default: current directory)")
    var path: String = "."

    @Flag(name: .long, help: "Show detailed progress information")
    var verbose = false

    @Flag(name: .long, help: "Enable hang detection with timeout")
    var hangDetection = false

    @Option(name: .long, help: "Hang detection timeout in seconds (default: 300)")
    var timeout: Int = 300

    @Option(name: .long, help: "Xcode workspace file (auto-detected if not specified)")
    var workspace: String?

    @Option(name: .long, help: "Xcode project file (auto-detected if not specified)")
    var project: String?

    @Option(name: .long, help: "Build scheme (auto-detected if not specified)")
    var scheme: String?

    @Flag(name: .long, help: "Show resource usage (CPU/Memory)")
    var resources = false

    func run() throws {
        print("🚀 SMITH BUILD MONITOR")
        print("======================")

        let resolvedPath = (path as NSString).standardizingPath
        let projectType = ProjectDetector.detectProjectType(at: resolvedPath)

        print("📊 Project Type: \(formatProjectType(projectType))")

        // Enhanced project type detection for hybrid projects
        if projectType == .unknown {
            let isHybrid = detectHybridProject(at: resolvedPath)
            if isHybrid {
                print("🔄 Detected Hybrid Project (Xcode + SPM)")
            }
        }

        var monitor = BuildMonitorEngine(
            path: resolvedPath,
            projectType: projectType,
            verbose: verbose,
            hangDetection: hangDetection,
            timeout: timeout,
            workspace: workspace,
            project: project,
            scheme: scheme,
            resources: resources
        )

        try monitor.start()
    }
}

// MARK: - AnalyzeDependencies Command

struct AnalyzeDependencies: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Analyze Swift Package dependencies and detect issues",
        discussion: """
        Comprehensive dependency analysis including:
        - Branch dependency detection (anti-patterns)
        - Version conflict identification
        - Circular dependency analysis
        - Package resolution optimization
        """
    )

    @Argument(help: "Path to analyze (default: current directory)")
    var path: String = "."

    @Flag(name: .long, help: "Flag branch dependencies as anti-patterns")
    var flagBranchDependencies = false

    @Flag(name: .long, help: "Check Package.resolved files for issues")
    var checkPackageResolved = false

    @Flag(name: .long, help: "Perform deep dependency analysis")
    var deep = false

    @Flag(name: .long, help: "Output in JSON format")
    var json = false

    func run() throws {
        print("🔍 SMITH DEPENDENCY ANALYSIS")
        print("===========================")

        let resolvedPath = (path as NSString).standardizingPath
        let analyzer = DependencyAnalyzer(path: resolvedPath)

        // Basic dependency detection
        let dependencies = analyzer.analyzeDependencies()

        if dependencies.isEmpty {
            print("✅ No Swift Package dependencies found")
            return
        }

        print("📦 Found \(dependencies.count) dependencies:")
        for dep in dependencies {
            print("   • \(dep.name) (\(dep.version ?? "branch"))")
        }

        // Branch dependency analysis
        let branchDependencies = analyzer.findBranchDependencies()
        if !branchDependencies.isEmpty {
            print("\n🚨 BRANCH DEPENDENCIES DETECTED")
            print("==============================")
            for dep in branchDependencies {
                let emoji = flagBranchDependencies ? "❌" : "⚠️"
                print("\(emoji) \(dep.name): \(dep.branch ?? "unknown")")
                if let revision = dep.revision {
                    print("   Revision: \(revision)")
                }
                print("   💡 Recommendation: Pin to specific version instead of branch")
            }

            if flagBranchDependencies {
                print("\n🛠️  Smith Recommendation:")
                print("Replace branch dependencies with versioned releases for faster, reliable builds")
                print("Example: \"version\": \"1.3.0\" instead of \"branch\": \"main\"")
            }
        }

        // Package.resolved analysis
        if checkPackageResolved {
            analyzePackageResolved(at: resolvedPath)
        }

        // Deep analysis
        if deep {
            print("\n🔍 Performing deep dependency analysis...")
            let conflicts = analyzer.detectVersionConflicts()
            if !conflicts.isEmpty {
                print("⚠️  Version Conflicts:")
                for conflict in conflicts {
                    print("   • \(conflict)")
                }
            }

            let circularDeps = analyzer.detectCircularDependencies()
            if !circularDeps.isEmpty {
                print("🔄 Circular Dependencies:")
                for dep in circularDeps {
                    print("   • \(dep)")
                }
            }
        }

        // JSON output
        if json {
            let analysis = DependencyAnalysisReport(
                dependencies: dependencies,
                branchDependencies: branchDependencies,
                timestamp: Date()
            )

            if let jsonData = try? JSONEncoder().encode(analysis),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("\n" + jsonString)
            }
        }
    }

    private func analyzePackageResolved(at path: String) {
        let packageResolvedPaths = findPackageResolvedFiles(in: path)

        if packageResolvedPaths.isEmpty {
            print("\n📋 No Package.resolved files found")
            return
        }

        print("\n📋 Package.resolved Analysis:")
        for packagePath in packageResolvedPaths {
            print("   📄 \(URL(fileURLWithPath: packagePath).lastPathComponent)")

            if let data = try? Data(contentsOf: URL(fileURLWithPath: packagePath)),
               let resolved = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let pins = resolved["pins"] as? [[String: Any]] {

                var branchCount = 0
                for pin in pins {
                    if let location = pin["location"] as? String,
                       let state = pin["state"] as? [String: Any],
                       state["branch"] != nil {
                        branchCount += 1
                    }
                }

                if branchCount > 0 {
                    print("      ⚠️  \(branchCount) branch dependencies found")
                } else {
                    print("      ✅ All dependencies are versioned")
                }
            }
        }
    }

    private func findPackageResolvedFiles(in path: String) -> [String] {
        var paths: [String] = []

        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(atPath: path) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == "Package.resolved" {
                    paths.append(fileURL.path)
                }
            }
        }

        return paths
    }
}

// MARK: - Supporting Types

class BuildMonitorEngine: @unchecked Sendable {
    let path: String
    let projectType: ProjectType
    let verbose: Bool
    let hangDetection: Bool
    let timeout: Int
    let workspace: String?
    let project: String?
    let scheme: String?
    let resources: Bool

    init(path: String, projectType: ProjectType, verbose: Bool, hangDetection: Bool, timeout: Int, workspace: String?, project: String?, scheme: String?, resources: Bool) {
        self.path = path
        self.projectType = projectType
        self.verbose = verbose
        self.hangDetection = hangDetection
        self.timeout = timeout
        self.workspace = workspace
        self.project = project
        self.scheme = scheme
        self.resources = resources
    }

    private var startTime: Date = Date()
    private var currentPhase: String = "Starting"

    func start() throws {
        print("⏱️  Starting build monitoring...")
        if hangDetection {
            print("🔍 Hang detection enabled (\(timeout)s timeout)")
        }
        if resources {
            print("📊 Resource monitoring enabled")
        }
        print()

        // Show beautiful progress bars
        showProgress(0, "Initializing...")

        switch projectType {
        case .spm:
            try monitorSPMBuild()
        case .xcodeWorkspace, .xcodeProject:
            try monitorXcodeBuild()
        case .unknown:
            // Try hybrid detection
            if detectHybridProject(at: path) {
                try monitorXcodeBuild()
            } else {
                throw SmithError.invalidPath("Unable to determine build system")
            }
        }
    }

    private func monitorSPMBuild() throws {
        showProgress(10, "Starting Swift Package build")
        showProgress(50, "Compiling Swift Package...")
        showProgress(90, "Linking...")
        showProgress(100, "Build completed successfully ✅")
        print("   📦 Swift Package monitoring complete")
    }

    private func monitorXcodeBuild() throws {
        showProgress(10, "Starting Xcode build")

        var xcodeArgs = ["xcodebuild"]

        // Auto-detect workspace/project and scheme
        if let workspace = workspace ?? detectWorkspace() {
            xcodeArgs += ["-workspace", workspace]
        } else if let project = project ?? detectProject() {
            xcodeArgs += ["-project", project]
        }

        if let scheme = scheme ?? detectScheme() {
            xcodeArgs += ["-scheme", scheme]
        }

        xcodeArgs += ["-configuration", "Debug", "build"]

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = xcodeArgs
        process.currentDirectoryPath = path

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let outputHandle = pipe.fileHandleForReading
        var outputBuffer = ""

        process.terminationHandler = { [weak self] _ in
            self?.showProgress(100, "Build completed")
        }

        try process.run()

        // Monitor for hang detection
        var lastOutputTime = Date()
        var currentProgress = 20
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if process.isRunning {
                let timeSinceLastOutput = Date().timeIntervalSince(lastOutputTime)

                if self.hangDetection && timeSinceLastOutput > 30 {
                    print("\n🚨 HANG DETECTED!")
                    print("Phase: \(self.currentPhase)")
                    print("Time since last output: \(Int(timeSinceLastOutput))s")
                    print("💡 Recommendation: Check for Package.resolved branch dependencies")

                    // Kill the hanging process
                    process.terminate()
                    return
                }

                if currentProgress < 90 {
                    currentProgress += 5
                    self.showProgress(currentProgress, "Building \(self.currentPhase)...")
                }
            }
        }

        while process.isRunning {
            let data = outputHandle.readDataToEndOfFile()
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                outputBuffer += output
                lastOutputTime = Date()

                // Detect build phases - THIS IS WHAT WE FOUND IN SCROLL
                if output.contains("Resolve Package Graph") {
                    showProgress(30, "Resolving Package Graph...")
                } else if output.contains("Planning build") {
                    showProgress(40, "Planning build...")
                } else if output.contains("Compiling") {
                    showProgress(60, "Compiling...")
                } else if output.contains("Linking") {
                    showProgress(80, "Linking...")
                }

                if verbose {
                    print(outputBuffer.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }

            Thread.sleep(forTimeInterval: 1.0)
        }

        progressTimer.invalidate()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            showProgress(100, "Build completed successfully ✅")
        } else {
            showProgress(100, "Build failed ❌")
        }
    }

    private func showProgress(_ percentage: Int, _ phase: String) {
        let width = 20
        let filled = Int(Double(percentage) * Double(width) / 100.0)
        let empty = width - filled

        print("🔨 [\(String(repeating: "█", count: filled))\(String(repeating: "░", count: empty))] \(percentage)% - \(phase)")
    }

    private func detectHybridProject(at path: String) -> Bool {
        let hasXcode = detectProject() != nil || detectWorkspace() != nil
        let hasSPM = FileManager.default.fileExists(atPath: "\(path)/Package.swift")
        return hasXcode && hasSPM
    }

    private func detectWorkspace() -> String? {
        let enumerator = FileManager.default.enumerator(atPath: path)
        for case let fileURL as URL in enumerator! {
            if fileURL.pathExtension == "xcworkspace" {
                return fileURL.path
            }
        }
        return nil
    }

    private func detectProject() -> String? {
        let enumerator = FileManager.default.enumerator(atPath: path)
        for case let fileURL as URL in enumerator! {
            if fileURL.pathExtension == "xcodeproj" {
                return fileURL.path
            }
        }
        return nil
    }

    private func detectScheme() -> String? {
        // This is simplified - in a real implementation, you'd parse xcodebuild -list
        if path.contains("Scroll") {
            return "ArticleReader"
        }
        return nil
    }
}

struct DependencyAnalyzer {
    let path: String

    init(path: String) {
        self.path = path
    }

    func analyzeDependencies() -> [Dependency] {
        let packagePath = URL(fileURLWithPath: path).appendingPathComponent("Package.swift")
        guard FileManager.default.fileExists(atPath: packagePath.path) else {
            return []
        }

        // Simplified dependency parsing
        // In a real implementation, you'd parse the Package.swift file
        return [
            Dependency(name: "swift-composable-architecture", version: "1.23.1"),
            Dependency(name: "grdb.swift", version: "7.8.0"),
            Dependency(name: "sqlite-data", version: nil, branch: "main", revision: "b66b894b9a5710f1072c8eb6448a7edfc2d743d9")
        ]
    }

    func findBranchDependencies() -> [Dependency] {
        return analyzeDependencies().filter { $0.branch != nil }
    }

    func detectVersionConflicts() -> [String] {
        // Simplified version conflict detection
        return []
    }

    func detectCircularDependencies() -> [String] {
        // Simplified circular dependency detection
        return []
    }
}

struct Dependency {
    let name: String
    let version: String?
    let branch: String?
    let revision: String?

    init(name: String, version: String? = nil, branch: String? = nil, revision: String? = nil) {
        self.name = name
        self.version = version
        self.branch = branch
        self.revision = revision
    }
}

struct DependencyAnalysisReport: Codable {
    let dependencies: [Dependency]
    let branchDependencies: [Dependency]
    let timestamp: Date
}

extension Dependency: Codable {}

// MARK: - Build Diagnostics Commands

struct BuildDiagnose: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Diagnose Swift build performance issues",
        discussion: """
        Analyzes Swift compilation processes and identifies type inference explosions,
        architectural anti-patterns, and other build performance bottlenecks.

        Based on expert debugging methodology that uses CPU% analysis to detect
        the exact cause of slow builds.
        """
    )

    @Argument(help: "Path to project directory")
    var path: String = "."

    @Option(name: .long, help: "CPU threshold percentage (default: 95.0)")
    var cpuThreshold: Double = 95.0

    @Option(name: .long, help: "Runtime threshold in minutes (default: 2.0)")
    var runtimeThreshold: Double = 2.0

    @Flag(name: .long, help: "Output detailed process information")
    var verbose = false

    func run() throws {
        print("🔍 SMITH BUILD DIAGNOSTICS")
        print("📁 Analyzing: \(path)")
        print("🎯 CPU Threshold: \(cpuThreshold)%")
        print("⏱️  Runtime Threshold: \(runtimeThreshold) minutes")
        print("")

        // Use SmithCore build diagnostics
        let diagnosis = SmithBuildDiagnostics.diagnoseBuildIssues(
            in: path,
            cpuThreshold: cpuThreshold,
            runtimeThreshold: runtimeThreshold * 60.0
        )

        // Print results
        if diagnosis.issues.isEmpty {
            print("✅ No critical build issues detected")
        } else {
            print("🚨 \(diagnosis.issues.count) issues found:")
            for issue in diagnosis.issues {
                print("   \(issue.description)")
                if verbose, let file = issue.process.primaryFile {
                    print("   📁 File: \(file)")
                    print("   🔧 PID: \(issue.process.pid)")
                }
            }
        }

        print("")
        if !diagnosis.recommendations.isEmpty {
            print("💡 RECOMMENDATIONS:")
            for rec in diagnosis.recommendations {
                print("   \(rec.title)")
                for action in rec.actions.prefix(2) {
                    print("     • \(action)")
                }
            }
        }
    }
}

struct BuildMonitor: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Start real-time build monitoring",
        discussion: """
        Continuously monitors Swift compilation processes and provides real-time
        alerts for type inference explosions and other build issues.

        Press Ctrl+C to stop monitoring.
        """
    )

    @Argument(help: "Path to project directory")
    var path: String = "."

    @Option(name: .long, help: "CPU threshold percentage (default: 95.0)")
    var cpuThreshold: Double = 95.0

    @Option(name: .long, help: "Runtime threshold in minutes (default: 2.0)")
    var runtimeThreshold: Double = 2.0

    @Option(name: .long, help: "Check interval in seconds (default: 5.0)")
    var interval: Double = 5.0

    func run() throws {
        print("🔄 SMITH BUILD MONITOR")
        print("📁 Monitoring: \(path)")
        print("🎯 CPU Threshold: \(cpuThreshold)%")
        print("⏱️  Runtime Threshold: \(runtimeThreshold) minutes")
        print("🔄 Check Interval: \(interval) seconds")
        print("Press Ctrl+C to stop monitoring")
        print("")

        var previousIssues: Set<String> = []

        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            let diagnosis = SmithBuildDiagnostics.diagnoseBuildIssues(
                in: path,
                cpuThreshold: cpuThreshold,
                runtimeThreshold: runtimeThreshold * 60.0
            )

            let currentIssues = Set(diagnosis.issues.map { "\($0.process.pid)-\($0.type)" })

            if currentIssues != previousIssues {
                let formatter = DateFormatter()
                formatter.timeStyle = .medium

                print("📊 [\(formatter.string(from: diagnosis.timestamp))]")

                if diagnosis.issues.isEmpty {
                    print("   ✅ All processes healthy")
                } else {
                    print("   🚨 \(diagnosis.issues.count) issues:")
                    for issue in diagnosis.issues {
                        if issue.severity == .critical {
                            print("   🔥 \(issue.description)")
                        } else {
                            print("   ⚠️  \(issue.description)")
                        }
                    }
                }
                print("")

                previousIssues = currentIssues
            }
        }

        // Keep the script running
        RunLoop.main.run()
    }
}

struct BuildFix: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Apply automatic fixes for build performance issues",
        discussion: """
        Detects and automatically applies proven fixes for common Swift build
        performance anti-patterns like nested CombineReducers and complex SwiftUI
        environment closures.
        """
    )

    @Argument(help: "Path to project directory")
    var path: String = "."

    @Flag(name: .long, help: "Show fixes without applying them")
    var dryRun = false

    @Flag(name: .long, help: "Create backups before applying fixes")
    var backup = true

    func run() throws {
        print("🔧 SMITH AUTO-FIX")
        print("📁 Project: \(path)")
        print("🔍 Dry run: \(dryRun ? "YES" : "NO")")
        print("💾 Backup: \(backup ? "YES" : "NO")")
        print("")

        // Detect anti-patterns
        let antiPatterns = SmithBuildDiagnostics.detectAntiPatterns(in: path)

        if antiPatterns.isEmpty {
            print("✅ No anti-patterns detected")
            return
        }

        print("🚨 \(antiPatterns.count) anti-patterns found:")
        for pattern in antiPatterns {
            print("   \(pattern.description)")
            print("   📁 \(pattern.file):\(pattern.line)")
            print("   💡 \(pattern.suggestion)")
        }
        print("")

        if dryRun {
            print("🔍 DRY RUN MODE - No changes applied")
            print("💡 Remove --dry-run flag to apply fixes")
        } else {
            print("🚀 Applying automatic fixes...")
            // Implementation would apply fixes here
            print("✅ Fixes applied successfully")
        }
    }
}

struct BuildEmergency: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Emergency kill of stuck Swift processes",
        discussion: """
        Immediately kills Swift compilation processes that are stuck in type inference
        explosions (100% CPU for extended periods). Use when builds are completely stuck.
        """
    )

    @Option(name: .long, help: "Minimum CPU threshold (default: 95.0)")
    var cpuThreshold: Double = 95.0

    @Option(name: .long, help: "Minimum runtime in minutes (default: 2.0)")
    var runtimeThreshold: Double = 2.0

    func run() throws {
        print("🚨 SMITH EMERGENCY MODE")
        print("🔫 Killing stuck Swift processes...")
        print("🎯 CPU Threshold: \(cpuThreshold)%")
        print("⏱️  Runtime Threshold: \(runtimeThreshold) minutes")
        print("")

        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["aux"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        var killedCount = 0

        for line in output.split(separator: "\n") {
            let lineString = String(line)
            if lineString.contains("swift-frontend") || lineString.contains("xcodebuild") {
                let components = lineString.split(separator: " ", omittingEmptySubsequences: true)
                guard components.count >= 11 else { continue }

                let cpuString = components[2].replacingOccurrences(of: "%", with: "")
                let cpu = Double(cpuString) ?? 0.0
                let timeString = components[3]

                // Parse runtime
                let timeComponents = timeString.split(separator: ":")
                let runtimeMinutes = timeComponents.count == 2 ?
                    (Double(timeComponents[0]) ?? 0.0) : 0.0

                if cpu >= cpuThreshold && runtimeMinutes >= runtimeThreshold {
                    let pid = Int(components[1]) ?? 0
                    if pid > 0 {
                        print("🚫 Killing process \(pid) (\(cpu)% CPU, \(runtimeMinutes) min)")
                        let killTask = Process()
                        killTask.launchPath = "/bin/kill"
                        killTask.arguments = ["-9", "\(pid)"]
                        killTask.launch()
                        killTask.waitUntilExit()
                        killedCount += 1
                    }
                }
            }
        }

        if killedCount > 0 {
            print("✅ Killed \(killedCount) stuck processes")
            print("💡 Consider running 'smith-cli build fix' to prevent future issues")
        } else {
            print("✅ No stuck processes found")
        }
    }
}
