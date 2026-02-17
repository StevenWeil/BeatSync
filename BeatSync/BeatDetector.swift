import Accelerate

class BeatDetector {
    // MARK: - History & Timing
    private var bassFluxHistory: [Float] = []
    private var midFluxHistory: [Float] = []
    private let historySize = 43
    private var lastBeatTime: Date = Date()
    private let minimumTimeBetweenBeats: TimeInterval = 0.2

    // MARK: - FFT Setup
    private let fftSetup: vDSP_DFT_Setup?
    private let fftLength = 2048

    // MARK: - Noise Floor
    // Prevents random quiet-room triggers — both conditions must be true for a beat
    private let minimumBassFlux: Float = 60.0
    private let minimumMidFlux: Float = 40.0

    // MARK: - Spectral Flux
    // Stores previous frame's magnitudes so we can measure change between frames
    // Vocals are sustained — they don't change frame to frame
    // Drums/claps are transients — they spike suddenly = high flux
    private var previousMagnitudes: [Float]

    init() {
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftLength), vDSP_DFT_Direction.FORWARD)
        previousMagnitudes = [Float](repeating: 0, count: fftLength / 2)
    }

    deinit {
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }

    // MARK: - Public Beat Detection
    func detectBeat(in samples: [Float]) -> Bool {
        let (bassFlux, midFlux) = extractFlux(from: samples)

        // Track flux history for both bands
        bassFluxHistory.append(bassFlux)
        midFluxHistory.append(midFlux)

        if bassFluxHistory.count > historySize {
            bassFluxHistory.removeFirst()
            midFluxHistory.removeFirst()
        }

        guard bassFluxHistory.count == historySize else { return false }

        // Bass threshold (kick drums, stomps)
        let avgBass = bassFluxHistory.reduce(0, +) / Float(historySize)
        let varBass = bassFluxHistory.map { pow($0 - avgBass, 2) }.reduce(0, +) / Float(historySize)
        let bassThreshold = avgBass + (sqrt(varBass) * 1.5)

        // Mid threshold (snare crack, hi-hats — 2k-6kHz, above vocal range)
        let avgMid = midFluxHistory.reduce(0, +) / Float(historySize)
        let varMid = midFluxHistory.map { pow($0 - avgMid, 2) }.reduce(0, +) / Float(historySize)
        let midThreshold = avgMid + (sqrt(varMid) * 1.5)

        let now = Date()
        let timeSinceLastBeat = now.timeIntervalSince(lastBeatTime)

        // Both adaptive threshold AND absolute minimum must be exceeded
        let isBassHit = bassFlux > bassThreshold && bassFlux > minimumBassFlux
        let isMidHit = midFlux > midThreshold && midFlux > minimumMidFlux

        if (isBassHit || isMidHit) && timeSinceLastBeat > minimumTimeBetweenBeats {
            lastBeatTime = now
            return true
        }

        return false
    }

    // MARK: - Spectral Flux Extraction
    private func extractFlux(from samples: [Float]) -> (bass: Float, mid: Float) {
        guard let fftSetup = fftSetup else { return (0, 0) }

        let processLength = min(samples.count, fftLength)
        var processedSamples = Array(samples.prefix(processLength))
        while processedSamples.count < fftLength {
            processedSamples.append(0)
        }

        var realIn = processedSamples
        var imagIn = [Float](repeating: 0, count: fftLength)
        var realOut = [Float](repeating: 0, count: fftLength)
        var imagOut = [Float](repeating: 0, count: fftLength)

        vDSP_DFT_Execute(fftSetup, &realIn, &imagIn, &realOut, &imagOut)

        // Compute magnitudes for this frame
        var magnitudes = [Float](repeating: 0, count: fftLength / 2)
        for i in 0..<fftLength / 2 {
            magnitudes[i] = sqrt(realOut[i] * realOut[i] + imagOut[i] * imagOut[i])
        }

        // Bass band (40-180 Hz) — kick drums, stomps
        let bassLowBin = Int(40 * Float(fftLength) / 44100)
        let bassHighBin = Int(180 * Float(fftLength) / 44100)

        // Mid band (2000-6000 Hz) — snare crack, hi-hats, above vocal range
        let midLowBin = Int(2000 * Float(fftLength) / 44100)
        let midHighBin = Int(6000 * Float(fftLength) / 44100)

        // Spectral flux with half-wave rectification
        // Only counts increases — ignores sustained sounds like vocals
        var bassFlux: Float = 0
        for i in bassLowBin...min(bassHighBin, magnitudes.count - 1) {
            let diff = magnitudes[i] - previousMagnitudes[i]
            bassFlux += max(0, diff)
        }

        var midFlux: Float = 0
        for i in midLowBin...min(midHighBin, magnitudes.count - 1) {
            let diff = magnitudes[i] - previousMagnitudes[i]
            midFlux += max(0, diff)
        }

        // Store this frame for next comparison
        previousMagnitudes = magnitudes

        return (bassFlux, midFlux)
    }
}
