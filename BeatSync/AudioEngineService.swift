import AVFoundation
import Accelerate
import Combine

class AudioEngineService: NSObject, ObservableObject {
    @Published var isListening = false
    
    private let audioEngine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 4096
    
    var onBeatDetected: (() -> Void)?
    
    private var beatDetector: BeatDetector?
    
    override init() {
        super.init()
        beatDetector = BeatDetector()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }
    
    func startListening() {
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
