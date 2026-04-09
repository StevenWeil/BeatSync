import AVFoundation
import Accelerate
import Combine
import UIKit

class AudioEngineService: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var wasInterrupted = false  // lets UI show "Interrupted" state if needed
    
    private let audioEngine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 4096
    
    var onBeatDetected: (() -> Void)?
    
    private var beatDetector: BeatDetector?
    
    override init() {
        super.init()
        beatDetector = BeatDetector()
        setupAudioSession()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }
    
    private func setupNotifications() {
        // Audio interruptions (calls, Siri, alarms)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        // Background/foreground transitions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Audio route changes (headphones unplugged, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    // MARK: - Interruption Handling
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            // Call, Siri, or alarm took over audio — stop cleanly
            if isListening {
                stopListening()
                DispatchQueue.main.async {
                    self.wasInterrupted = true
                }
            }
            
        case .ended:
            // Interruption is over — check if we should reactivate the audio session
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                // System says it's safe to resume — reactivate session but don't auto-restart
                // listening. Let the user decide to tap Start again.
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    print("Failed to reactivate audio session after interruption: \(error)")
                }
            }
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Background/Foreground Handling
    
    @objc private func handleResignActive() {
        // App going to background or interrupted by system UI (Control Center, etc.)
        // AVAudioEngine cannot run reliably in background without background audio entitlement
        if isListening {
            stopListening()
            DispatchQueue.main.async {
                self.wasInterrupted = true
            }
        }
    }
    
    @objc private func handleBecomeActive() {
        // App returned to foreground — reactivate audio session so it's ready when user taps Start
        // We do NOT auto-resume; wasInterrupted flag lets the UI inform the user
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to reactivate audio session on foreground: \(error)")
        }
    }
    
    // MARK: - Route Change Handling
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        // If the mic source disappears (e.g. headset with mic unplugged), stop cleanly
        if reason == .oldDeviceUnavailable && isListening {
            DispatchQueue.main.async {
                self.stopListening()
                self.wasInterrupted = true
            }
        }
    }
    
    // MARK: - Core Listening
    
    func startListening() {
        // Clear any prior interrupted state
        wasInterrupted = false
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            print("Audio engine start error: \(error)")
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        if let isBeat = beatDetector?.detectBeat(in: samples) {
            if isBeat {
                DispatchQueue.main.async {
                    self.onBeatDetected?()
                }
            }
        }
    }
}
