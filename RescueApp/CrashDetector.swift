import Foundation
import CoreMotion

class CrashDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private let impactThreshold: Double = 3.8
    @Published var isCrashDetected: Bool = false
    var onCrashDetected: (() -> Void)?

    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.05
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, _) in
            guard let self = self, let data = data else { return }
            let totalG = sqrt(pow(data.acceleration.x, 2) + pow(data.acceleration.y, 2) + pow(data.acceleration.z, 2))
            if totalG > self.impactThreshold {
                self.stopMonitoring()
                self.isCrashDetected = true
                self.onCrashDetected?()
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
    }
}
