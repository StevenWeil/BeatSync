import SwiftUI

struct ContentView: View {
    @StateObject private var flashlight = FlashlightService()
    @StateObject private var audioEngine = AudioEngineService()
    
    @State private var showManualSheet = false
    @State private var showSettingsSheet = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // ---- HEADER ----
                VStack(spacing: 8) {
                    Text("BeatSync")
                        .font(.system(size: 42, weight: .thin, design: .default))
                        .foregroundColor(Color(red: 0, green: 0.71, blue: 1.0))
                        .tracking(6)
                    
                    Text("bring the party to life")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(white: 0.5))
                        .tracking(2)
                }
                .padding(.top, 70)
                
                Spacer()
                
                // ---- MAIN BUTTON ----
                VStack(spacing: 24) {
                    ZStack {
                        if audioEngine.isListening {
                            Circle()
                                .stroke(Color(red: 0, green: 0.71, blue: 1.0).opacity(0.15), lineWidth: 1)
                                .frame(width: 220, height: 220)
                            Circle()
                                .stroke(Color(red: 0, green: 0.71, blue: 1.0).opacity(0.08), lineWidth: 1)
                                .frame(width: 260, height: 260)
                        }
                        
                        Button(action: {
                            if audioEngine.isListening {
                                stopListening()
                            } else {
                                startListening()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(audioEngine.isListening
                                          ? Color(red: 0, green: 0.71, blue: 1.0).opacity(0.15)
                                          : Color(white: 0.08))
                                    .frame(width: 180, height: 180)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                audioEngine.isListening
                                                ? Color(red: 0, green: 0.71, blue: 1.0).opacity(0.8)
                                                : Color(white: 0.2),
                                                lineWidth: 1.5
                                            )
                                    )
                                
                                VStack(spacing: 10) {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 32, weight: .ultraLight))
                                        .foregroundColor(audioEngine.isListening
                                                         ? Color(red: 0, green: 0.71, blue: 1.0)
                                                         : Color(white: 0.6))
                                    
                                    Text(audioEngine.isListening ? "listening..." : "start listening")
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(audioEngine.isListening
                                                         ? Color(red: 0, green: 0.71, blue: 1.0)
                                                         : Color(white: 0.5))
                                        .tracking(1)
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: audioEngine.isListening)
                    }
                    
                    Text(audioEngine.isListening ? "syncing to the beat" : "tap to start")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(Color(white: 0.35))
                        .tracking(2)
                }
                
                Spacer()
                
                // ---- BOTTOM TABS ----
                HStack(spacing: 0) {
                    Button(action: {
                        showManualSheet = true
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: flashlight.isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(flashlight.isOn ? .yellow : Color(white: 0.4))
                            Text("flashlight")
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(Color(white: 0.35))
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    
                    Rectangle()
                        .fill(Color(white: 0.12))
                        .frame(width: 1, height: 40)
                    
                    Button(action: {
                        showSettingsSheet = true
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(Color(white: 0.4))
                            Text("settings")
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(Color(white: 0.35))
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                }
                .background(Color(white: 0.05))
                .overlay(
                    Rectangle()
                        .fill(Color(white: 0.1))
                        .frame(height: 1),
                    alignment: .top
                )
            }
            
            if !flashlight.isFlashlightAvailable {
                VStack {
                    Text("⚠️ Flashlight not available on this device")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                    Spacer()
                }
            }
        }
        
        // ---- MANUAL FLASHLIGHT SHEET ----
        .sheet(isPresented: $showManualSheet) {
            ZStack {
                Color(white: 0.05).ignoresSafeArea()
                
                VStack(spacing: 40) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 16)
                    
                    Text("Flashlight")
                        .font(.system(size: 22, weight: .thin))
                        .foregroundColor(.white)
                        .tracking(4)
                    
                    Button(action: { flashlight.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(flashlight.isOn
                                      ? Color.yellow.opacity(0.15)
                                      : Color(white: 0.08))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            flashlight.isOn
                                            ? Color.yellow.opacity(0.7)
                                            : Color(white: 0.2),
                                            lineWidth: 1.5
                                        )
                                )
                            
                            Image(systemName: flashlight.isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 44, weight: .ultraLight))
                                .foregroundColor(flashlight.isOn ? .yellow : Color(white: 0.4))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: flashlight.isOn)
                    
                    Text(flashlight.isOn ? "on" : "off")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(Color(white: 0.35))
                        .tracking(3)
                    
                    Spacer()
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
        
        // ---- SETTINGS SHEET ----
        .sheet(isPresented: $showSettingsSheet) {
            ZStack {
                Color(white: 0.05).ignoresSafeArea()
                
                VStack(spacing: 40) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 16)
                    
                    Text("Settings")
                        .font(.system(size: 22, weight: .thin))
                        .foregroundColor(.white)
                        .tracking(4)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Brightness")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(white: 0.5))
                                .tracking(1)
                            Spacer()
                            Text("\(Int(flashlight.brightness * 100))%")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(white: 0.4))
                        }
                        
                        Slider(value: Binding(
                            get: { flashlight.brightness },
                            set: { flashlight.updateBrightness($0) }
                        ), in: 0.01...1.0)
                        .accentColor(Color(red: 0, green: 0.71, blue: 1.0))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color(white: 0.08))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
    }
    
    private func startListening() {
        if flashlight.isOn { flashlight.turnOff() }
        audioEngine.onBeatDetected = { pulseFlashlight() }
        audioEngine.startListening()
    }
    
    private func stopListening() {
        audioEngine.stopListening()
        flashlight.turnOff()
    }
    
    private func pulseFlashlight() {
        flashlight.turnOn()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            flashlight.turnOff()
        }
    }
}

#Preview {
    ContentView()
}
