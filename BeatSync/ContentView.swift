import SwiftUI

struct ContentView: View {
    @StateObject private var flashlight = FlashlightService()
    @StateObject private var audioEngine = AudioEngineService()
    
    var body: some View {
        VStack(spacing: 30) {
            // Flashlight icon
            Image(systemName: flashlight.isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.system(size: 100))
                .foregroundColor(flashlight.isOn ? .yellow : .gray)
                .animation(.easeInOut, value: flashlight.isOn)
            
            // Manual Mode Section
            VStack(spacing: 15) {
                Text("Manual Mode")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // Toggle button
                Button(action: {
                    flashlight.toggle()
                }) {
                    Text(flashlight.isOn ? "Turn Off" : "Turn On")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(flashlight.isOn ? Color.red : Color.blue)
                        .cornerRadius(15)
                }
                
                // Brightness slider
                VStack(spacing: 10) {
                    Text("Brightness: \(Int(flashlight.brightness * 100))%")
                        .font(.headline)
                    
                    Slider(value: Binding(
                        get: { flashlight.brightness },
                        set: { flashlight.updateBrightness($0) }
                    ), in: 0.01...1.0)
                    .padding(.horizontal, 40)
                }
            }
            
            Divider()
                .padding(.vertical, 10)
            
            // Listening Mode Section
            VStack(spacing: 15) {
                Text("Listening Mode")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(audioEngine.isListening ? "🎵 Listening for beats..." : "Ready to sync")
                    .font(.subheadline)
                    .foregroundColor(audioEngine.isListening ? .green : .secondary)
                
                Button(action: {
                    if audioEngine.isListening {
                        stopListening()
                    } else {
                        startListening()
                    }
                }) {
                    Text(audioEngine.isListening ? "Stop Listening" : "Start Listening")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(audioEngine.isListening ? Color.red : Color.green)
                        .cornerRadius(15)
                }
            }
            
            // Device compatibility warning
            if !flashlight.isFlashlightAvailable {
                Text("⚠️ Flashlight not available on this device")
                    .foregroundColor(.orange)
                    .padding()
            }
        }
        .padding()
    }
    
    private func startListening() {
        // Turn off manual mode if it's on
        if flashlight.isOn {
            flashlight.turnOff()
        }
        
        // Set up beat callback
        audioEngine.onBeatDetected = {
            pulseFlashlight()
        }
        
        audioEngine.startListening()
    }
    
    private func stopListening() {
        audioEngine.stopListening()
        flashlight.turnOff()
    }
    
    private func pulseFlashlight() {
        // Quick flash on beat
        flashlight.turnOn()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            flashlight.turnOff()
        }
    }
}

#Preview {
    ContentView()
}
