import Foundation
import SwiftUI

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("acoustIDApiKey") var acoustIDApiKey: String = ""
    @AppStorage("bufferDuration") var bufferDuration: Double = Constants.Audio.defaultBufferDuration
    @AppStorage("detectionInterval") var detectionInterval: Double = Constants.Detection.defaultInterval
    @AppStorage("confidenceThreshold") var confidenceThreshold: Double = Constants.Detection.defaultConfidenceThreshold
    @AppStorage("cooldownDuration") var cooldownDuration: Double = Constants.Detection.defaultCooldownDuration
    @AppStorage("perTrackCooldown") var perTrackCooldown: Double = Constants.Detection.defaultPerTrackCooldown
    @AppStorage("autoDetectionEnabled") var autoDetectionEnabled: Bool = true
    @AppStorage("gapDetectionEnabled") var gapDetectionEnabled: Bool = false
    @AppStorage("fallbackProviderEnabled") var fallbackProviderEnabled: Bool = true
    @AppStorage("debugModeEnabled") var debugModeEnabled: Bool = false

    private init() {}
}
