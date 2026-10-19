import Foundation
import CoreMotion
import Combine

/// Real-time classification of device movement to protect PPG signal integrity.
public enum DeviceMotionStability: Sendable {
    case stable
    case moderateMotion
    case excessiveMotion
    
    public var isUsableForPPG: Bool {
        self != .excessiveMotion
    }
}

/// Abstract contract for motion artifact monitoring service to facilitate testing.
public protocol MotionArtifactServiceProtocol: Sendable {
    var motionStabilityPublisher: AnyPublisher<DeviceMotionStability, Never> { get }
    var currentStability: DeviceMotionStability { get }
    func startMonitoring()
    func stopMonitoring()
}

/// On-device motion stabilization and rejection system using Apple's CoreMotion framework.
public final class MotionArtifactFilterService: MotionArtifactServiceProtocol, @unchecked Sendable {
    private let motionManager = CMMotionManager()
    private let stabilitySubject = CurrentValueSubject<DeviceMotionStability, Never>(.stable)
    private let queue = OperationQueue()
    
    public var motionStabilityPublisher: AnyPublisher<DeviceMotionStability, Never> {
        stabilitySubject.eraseToAnyPublisher()
    }
    
    public var currentStability: DeviceMotionStability {
        stabilitySubject.value
    }
    
    public init() {
        queue.name = "com.hemosight.motion.processing"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
    }
    
    deinit {
        stopMonitoring()
    }
    
    public func startMonitoring() {
        guard !motionManager.isDeviceMotionActive else { return }
        guard motionManager.isDeviceMotionAvailable else {
            stabilitySubject.send(.stable)
            return
        }
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 // 50 Hz
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            let state = Self.computeStability(
                userAcceleration: motion.userAcceleration,
                rotationRate: motion.rotationRate
            )
            
            if state != self.stabilitySubject.value {
                self.stabilitySubject.send(state)
            }
        }
    }
    
    public func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        stabilitySubject.send(.stable)
    }
    
    /// Pure computation of composite motion metric and stability classification.
    public static func computeStability(
        userAcceleration: CMAcceleration,
        rotationRate: CMRotationRate
    ) -> DeviceMotionStability {
        let accelMagnitude = sqrt(
            userAcceleration.x * userAcceleration.x +
            userAcceleration.y * userAcceleration.y +
            userAcceleration.z * userAcceleration.z
        )
        let gyroMagnitude = sqrt(
            rotationRate.x * rotationRate.x +
            rotationRate.y * rotationRate.y +
            rotationRate.z * rotationRate.z
        )
        let compositeMotion = accelMagnitude + (0.05 * gyroMagnitude)
        
        if compositeMotion > 0.35 {
            return .excessiveMotion
        } else if compositeMotion > 0.15 {
            return .moderateMotion
        } else {
            return .stable
        }
    }
}

// MARK: - Test Double (SpyingStub)

#if DEBUG
public final class MotionArtifactServiceSpyingStub: MotionArtifactServiceProtocol, @unchecked Sendable {
    public let stabilitySubject = CurrentValueSubject<DeviceMotionStability, Never>(.stable)
    public private(set) var startMonitoringCallCount = 0
    public private(set) var stopMonitoringCallCount = 0
    
    public var motionStabilityPublisher: AnyPublisher<DeviceMotionStability, Never> {
        stabilitySubject.eraseToAnyPublisher()
    }
    
    public var currentStability: DeviceMotionStability {
        stabilitySubject.value
    }
    
    public init(initialStability: DeviceMotionStability = .stable) {
        self.stabilitySubject.send(initialStability)
    }
    
    public func startMonitoring() {
        startMonitoringCallCount += 1
    }
    
    public func stopMonitoring() {
        stopMonitoringCallCount += 1
        stabilitySubject.send(.stable)
    }
    
    public func emitStability(_ stability: DeviceMotionStability) {
        stabilitySubject.send(stability)
    }
}
#endif
