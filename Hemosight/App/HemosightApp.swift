import SwiftUI

/// Main Application Entry Point for Hemosight (ทัศนโลหิต)
/// On-device microvascular and 3D morphometric limb ischemia screening system.
@main
struct HemosightApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            HomeDashboardView()
                .environmentObject(appState)
                .preferredColorScheme(.dark) // High-contrast clinical dark mode
        }
    }
}

/// Shared Global Reactive App State
public final class AppState: ObservableObject {
    @Published public var currentPatient: PatientProfile = PatientProfile.elderlyDialysisPatient
    @Published public var currentCRT: CRTMeasurement?
    @Published public var currentLimbScan: LimbScanData?
    @Published public var currentReport: RiskReport?
    @Published public var historicalReports: [RiskReport] = []
    
    // Core Evaluator
    public let riskEvaluator = RiskEvaluator()
    
    public init() {
        // Seed with a sample previous historical scan for immediate demonstration
        let samplePrevious = RiskReport.sampleMock(tier: .moderate)
        self.historicalReports.append(samplePrevious)
    }
    
    public func runEvaluation() -> RiskReport {
        let report = riskEvaluator.evaluateRisk(
            crt: currentCRT,
            limb: currentLimbScan,
            patient: currentPatient
        )
        self.currentReport = report
        self.historicalReports.insert(report, at: 0)
        return report
    }
    
    public func resetCurrentScan() {
        currentCRT = nil
        currentLimbScan = nil
        currentReport = nil
    }
}
