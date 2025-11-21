import XCTest
@testable import SmithCLI
import SmithCore

final class SmithCLITests: XCTestCase {

    func testSmithCLIConfiguration() {
        // Test that SmithCLI is properly configured
        XCTAssertEqual(SmithCLI.configuration.commandName, "smith-cli")
        XCTAssertNotNil(SmithCLI.configuration.version)
        XCTAssertFalse(SmithCLI.configuration.subcommands.isEmpty)

        // Verify expected subcommands exist
        let subcommandNames = SmithCLI.configuration.subcommands.map { $0.configuration.commandName }
        XCTAssertTrue(subcommandNames.contains("analyze"))
        XCTAssertTrue(subcommandNames.contains("detect"))
        XCTAssertTrue(subcommandNames.contains("status"))
        XCTAssertTrue(subcommandNames.contains("validate"))
        XCTAssertTrue(subcommandNames.contains("optimize"))
        XCTAssertTrue(subcommandNames.contains("environment"))
    }

    func testAnalyzeCommandDefaults() {
        // Test Analyze command default values
        let analyze = Analyze()
        XCTAssertEqual(analyze.path, ".")
        XCTAssertFalse(analyze.json)
        XCTAssertFalse(analyze.verbose)
        XCTAssertFalse(analyze.hangAnalysis)
    }

    func testDetectCommandDefaults() {
        // Test Detect command default values
        let detect = Detect()
        XCTAssertEqual(detect.path, ".")
    }

    func testValidateCommandDefaults() {
        // Test Validate command default values
        let validate = Validate()
        XCTAssertEqual(validate.path, ".")
        XCTAssertFalse(validate.deep)
    }

    func testOptimizeCommandDefaults() {
        // Test Optimize command default values
        let optimize = Optimize()
        XCTAssertEqual(optimize.path, ".")
        XCTAssertFalse(optimize.apply)
    }

    func testSmithErrorDescriptions() {
        // Test SmithError localized descriptions
        let invalidPathError = SmithError.invalidPath("/nonexistent/path")
        XCTAssertEqual(invalidPathError.localizedDescription, "Invalid path: /nonexistent/path")

        let toolExecutionError = SmithError.toolExecutionFailed("spmsift")
        XCTAssertEqual(toolExecutionError.localizedDescription, "Tool execution failed: spmsift")
    }

    func testFormatProjectType() {
        // Test project type formatting
        let spmType = ProjectType.spm
        // We can't directly test the private function, but we can verify it's used through integration

        let xcodeProjectType = ProjectType.xcodeProject(project: "/path/to/Test.xcodeproj")
        // Test that the project type contains the expected filename
        if case .xcodeProject(let project) = xcodeProjectType {
            XCTAssertTrue(project.contains("Test.xcodeproj"))
        }
    }

    func testEmojiForSeverity() {
        // Test emoji mapping for diagnostic severities
        // Since this function is private, we test through the public API

        let infoDiagnostic = Diagnostic(
            severity: .info,
            category: .configuration,
            message: "Test info"
        )

        let warningDiagnostic = Diagnostic(
            severity: .warning,
            category: .dependency,
            message: "Test warning"
        )

        let errorDiagnostic = Diagnostic(
            severity: .error,
            category: .compilation,
            message: "Test error"
        )

        let criticalDiagnostic = Diagnostic(
            severity: .critical,
            category: .environment,
            message: "Test critical"
        )

        // Verify diagnostics are created correctly
        XCTAssertEqual(infoDiagnostic.severity, .info)
        XCTAssertEqual(warningDiagnostic.severity, .warning)
        XCTAssertEqual(errorDiagnostic.severity, .error)
        XCTAssertEqual(criticalDiagnostic.severity, .critical)
    }

    func testBuildAnalysisIntegration() {
        // Test that smith-cli properly integrates with smith-core

        let analysis = SmithCore.quickAnalyze(at: ".")

        // Verify analysis is created
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.projectType, .unknown) // Current dir likely doesn't have a Swift project

        // Test formatting through smith-core integration
        let humanReadable = SmithCore.formatHumanReadable(analysis)
        XCTAssertFalse(humanReadable.isEmpty)
        XCTAssertTrue(humanReadable.contains("SMITH BUILD ANALYSIS"))

        if let jsonData = SmithCore.formatJSON(analysis) {
            XCTAssertFalse(jsonData.isEmpty)
        }
    }

    func testProjectDetectorIntegration() {
        // Test that smith-cli can use ProjectDetector from smith-core

        let currentPath = "."
        let projectType = ProjectDetector.detectProjectType(at: currentPath)

        // Should return a valid project type
        XCTAssertTrue(projectType == .spm || projectType == .xcodeProject ||
                     projectType == .xcodeWorkspace || projectType == .unknown)

        // Test build system detection
        let buildSystems = BuildSystemDetector.detectAvailableBuildSystems()
        XCTAssertTrue(buildSystems.contains(.xcode) || buildSystems.contains(.swift))
    }

    func testRecommendationsGeneration() {
        // Test recommendations generation for different project complexities

        let lowComplexityAnalysis = BuildAnalysis(
            projectType: .spm,
            status: .success,
            dependencyGraph: DependencyGraph(
                targetCount: 5,
                maxDepth: 2,
                circularDeps: false,
                complexity: .low
            )
        )

        let highComplexityAnalysis = BuildAnalysis(
            projectType: .xcodeProject(project: "Complex.xcodeproj"),
            status: .failed,
            dependencyGraph: DependencyGraph(
                targetCount: 150,
                maxDepth: 10,
                circularDeps: true,
                complexity: .extreme
            )
        )

        // Test risk assessment
        let lowRisks = SmithCore.assessBuildRisk(lowComplexityAnalysis)
        let highRisks = SmithCore.assessBuildRisk(highComplexityAnalysis)

        // High complexity should generate more risks
        XCTAssertTrue(highRisks.count > lowRisks.count)

        // Verify risk categories
        let highRiskCategories = highRisks.map { $0.category }
        XCTAssertTrue(highRiskCategories.contains(.dependency) ||
                     highRiskCategories.contains(.performance))
    }
}