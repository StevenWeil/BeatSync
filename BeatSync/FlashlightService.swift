import AVFoundation
import Combine

class FlashlightService: ObservableObject {
    @Published var isOn = false
    @Published var brightness: Float = 1.0
    @Published var isFlashlightAvailable = false
    
    private var device: AVCaptureDevice?
    
    init() {
        device = AVCaptureDevice.default(for: .video)
        isFlashlightAvailable = device?.hasTorch ?? false
    }
    
    func toggle() {
        if isOn {
            turnOff()
        } else {
            turnOn()
        }
    }
    
    func turnOn() {
        guard let device = device, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            try device.setTorchModeOn(level: max(0.01, brightness))
            device.unlockForConfiguration()
            isOn = true
        } catch {
            print("Flashlight error: \(error)")
        }
    }
    
    func turnOff() {
        guard let device = device, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            device.unlockForConfiguration()
            isOn = false
        } catch {
            print("Flashlight error: \(error)")
        }
    }
    
    func updateBrightness(_ newBrightness: Float) {
        brightness = newBrightness
        if isOn {
            turnOn() // Reapply with new brightness
        }
    }
}
