import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("API Configuration") {
                SecureField("AcoustID API Key", text: $settings.acoustIDApiKey)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Audio") {
                HStack {
                    Text("Buffer Duration")
                    Spacer()
                    Text("\(Int(settings.bufferDuration))s")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: $settings.bufferDuration,
                    in: Constants.Audio.minBufferDuration...Constants.Audio.maxBufferDuration,
                    step: 1
                )
            }

            Section("Detection") {
                HStack {
                    Text("Detection Interval")
                    Spacer()
                    Text("\(Int(settings.detectionInterval))s")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(
                    value: $settings.detectionInterval,
                    in: Constants.Detection.minInterval...Constants.Detection.maxInterval,
                    step: 10
                )

                HStack {
                    Text("Confidence Threshold")
                    Spacer()
                    Text("\(Int(settings.confidenceThreshold * 100))%")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.confidenceThreshold, in: 0.1...1.0, step: 0.05)

                HStack {
                    Text("Cooldown Duration")
                    Spacer()
                    Text("\(Int(settings.cooldownDuration))s")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.cooldownDuration, in: 10...120, step: 5)

                HStack {
                    Text("Per-Track Cooldown")
                    Spacer()
                    Text("\(Int(settings.perTrackCooldown))s")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $settings.perTrackCooldown, in: 60...600, step: 30)
            }

            Section("Features") {
                Toggle("Auto Detection", isOn: $settings.autoDetectionEnabled)
                Toggle("Gap Detection", isOn: $settings.gapDetectionEnabled)
                Toggle("Fallback Provider", isOn: $settings.fallbackProviderEnabled)
                Toggle("Debug Mode", isOn: $settings.debugModeEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 520)
        .padding()
    }
}
