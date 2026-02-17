import Accelerate

class BeatDetector {
    private var bassEnergyHistory: [Float] = []
    private var midEnergyHistory: [Float] = []
    private let historySize = 43
    private var lastBeatTime: Date = Date()
    private let minimumTimeBetweenBeats: TimeInterval = 0.2
    
    // FFT setup
    private let fftSetup: vDSP_DFT_Setup?
    private let fftLength = 2048
    
    init() {
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftLength), vDSP_DFT_Direction.FORWARD)
    }
    
    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }
    
    func detectBeat(in samples: [Float]) -> Bool {
        let (bassEnergy, midEnergy) = extractEnergy(from: samples)
        
        // Track both bass and mid-range
        bassEnergyHistory.append(bassEnergy)
        midEnergyHistory.append(midEnergy)
        
        if bassEnergyHistory.count > historySize {
            bassEnergyHistory.removeFirst()
            midEnergyHistory.removeFirst()
        }
        
        guard bassEnergyHistory.count == historySize else { return false }
        
        // Bass detection (stomp)
        let avgBass = bassEnergyHistory.reduce(0, +) / Float(historySize)
        let varBass = bassEnergyHistory.map { pow($0 - avgBass, 2) }.reduce(0, +) / Float(historySize)
        let bassThreshold = avgBass + (sqrt(varBass) * 0.8)
        
        // Mid detection (clap)
        let avgMid = midEnergyHistory.reduce(0, +) / Float(historySize)
        let varMid = midEnergyHistory.map { pow($0 - avgMid, 2) }.reduce(0, +) / Float(historySize)
        let midThreshold = avgMid + (sqrt(varMid) * 0.9)
        
        let now = Date()
        let timeSinceLastBeat = now.timeIntervalSince(lastBeatTime)
        
        // Detect if EITHER bass OR mid exceeds threshold
        let isBassHit = bassEnergy > bassThreshold
        let isMidHit = midEnergy > midThreshold
        
        if (isBassHit || isMidHit) && timeSinceLastBeat > minimumTimeBetweenBeats {
            lastBeatTime = now
            return true
        }
        
        return false
    }
    
    private func extractEnergy(from samples: [Float]) -> (bass: Float, mid: Float) {
        guard let fftSetup = fftSetup else { return (0, 0) }
        
        let processLength = min(samples.count, fftLength)
        var processedSamples = Array(samples.prefix(processLength))
        
        while processedSamples.count < fftLength {
            processedSamples.append(0)
        }
        
        var realIn = [Float](repeating: 0, count: fftLength)
        var imagIn = [Float](repeating: 0, count: fftLength)
        var realOut = [Float](repeating: 0, count: fftLength)
        var imagOut = [Float](repeating: 0, count: fftLength)
        
        realIn = processedSamples
        
        vDSP_DFT_Execute(fftSetup, &realIn, &imagIn, &realOut, &imagOut)
        
        var magnitudes = [Float](repeating: 0, count: fftLength / 2)
        for i in 0..<fftLength / 2 {
            magnitudes[i] = sqrt(realOut[i] * realOut[i] + imagOut[i] * imagOut[i])
        }
        
        let sampleRate: Float = 44100
        
        // Bass range (40-180 Hz) - catches kick drum/stomp
        let bassLowBin = Int(40 * Float(fftLength) / sampleRate)
        let bassHighBin = Int(180 * Float(fftLength) / sampleRate)
        
        var bassEnergy: Float = 0
        for i in bassLowBin...min(bassHighBin, magnitudes.count - 1) {
            bassEnergy += magnitudes[i]
        }
        
        // Mid range (800-2000 Hz) - catches clap/snare
        let midLowBin = Int(800 * Float(fftLength) / sampleRate)
        let midHighBin = Int(2000 * Float(fftLength) / sampleRate)
        
        var midEnergy: Float = 0
        for i in midLowBin...min(midHighBin, magnitudes.count - 1) {
            midEnergy += magnitudes[i]
        }
        
        return (bassEnergy, midEnergy)
    }
}
