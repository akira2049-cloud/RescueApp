import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var crashDetector = CrashDetector()
    
    // REPLACE WITH YOUR EMERGENCY CONTACT NUMBER
    @State private var emergencyContact = EmergencyContact(name: "Family Contact", phoneNumberWithCountryCode: "14155552671")
    @State private var showCountdownModal = false
    @State private var countdownTimer = 10
    @State private var timer: Timer? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("Accident Guard Active")
                        .font(.title2.bold())
                    Text("Background GPS tracking & crash detection active.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    Text("GPS STATUS")
                        .font(.caption.bold())
                        .foregroundColor(.gray)
                    if let location = locationManager.lastLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text("Lat: \(location.coordinate.latitude, specifier: "%.5f")")
                            Text("Lon: \(location.coordinate.longitude, specifier: "%.5f")")
                        }
                        .font(.system(.body, design: .monospaced))
                    } else {
                        Text("Acquiring GPS Signal...")
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                Button(action: { startEmergencyCountdown() }) {
                    HStack {
                        Image(systemName: "sos")
                        Text("TEST SOS ALERT")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("RescueApp")
            .onAppear {
                locationManager.requestPermissions()
                crashDetector.startMonitoring()
                crashDetector.onCrashDetected = { startEmergencyCountdown() }
            }
            .fullScreenCover(isPresented: $showCountdownModal) {
                ZStack {
                    Color.red.ignoresSafeArea()
                    VStack(spacing: 30) {
                        Text("CRASH DETECTED!")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.white)
                        Text("Sending location via WhatsApp in:")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(countdownTimer)")
                            .font(.system(size: 90, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Button(action: cancelAlert) {
                            Text("I'M OK - CANCEL")
                                .font(.title3.bold())
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
        }
    }

    private func startEmergencyCountdown() {
        countdownTimer = 10
        showCountdownModal = true
        AudioServicesPlaySystemSound(1304)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdownTimer > 1 {
                countdownTimer -= 1
            } else {
                timer?.invalidate()
                showCountdownModal = false
                if let location = locationManager.lastLocation {
                    WhatsAppDispatcher.shared.sendEmergencyLocation(to: emergencyContact, location: location)
                }
            }
        }
    }

    private func cancelAlert() {
        timer?.invalidate()
        showCountdownModal = false
        crashDetector.startMonitoring()
    }
}
