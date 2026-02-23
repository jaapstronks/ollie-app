//
//  AudioService.swift
//  Ollie-app
//
//  Audio service for playing training clicker sounds
//

import AVFoundation

/// Service for playing audio feedback during training sessions
@MainActor
final class AudioService {
    static let shared = AudioService()

    private var clickPlayer: AVAudioPlayer?
    private var isEnabled = true

    private init() {
        setupAudioSession()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            // Configure audio session for playback that mixes with other audio
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
        } catch {
            print("AudioService: Failed to configure audio session: \(error)")
        }
    }

    /// Pre-load the click sound for instant playback
    func prepareClickSound() {
        // First try to load from bundle
        if let url = Bundle.main.url(forResource: "click", withExtension: "caf") {
            do {
                clickPlayer = try AVAudioPlayer(contentsOf: url)
                clickPlayer?.prepareToPlay()
                clickPlayer?.volume = 0.8
                return
            } catch {
                print("AudioService: Failed to load click sound from bundle: \(error)")
            }
        }

        // Fallback: Generate a simple click sound programmatically
        generateClickSound()
    }

    /// Generate a click sound programmatically (fallback if no audio file)
    private func generateClickSound() {
        // Generate a short click using AudioToolbox
        // This creates a ~50ms sine wave burst at 2000 Hz
        let sampleRate: Double = 44100
        let duration: Double = 0.05  // 50ms
        let frequency: Double = 2000  // 2kHz
        let samples = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: samples)

        for i in 0..<samples {
            let t = Double(i) / sampleRate
            // Sharp attack, fast exponential decay
            let envelope = exp(-t * 80)
            audioData[i] = Float(sin(2 * .pi * frequency * t) * envelope * 0.8)
        }

        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("click_generated.wav")

        // Write WAV file
        if let audioFile = try? AVAudioFile(
            forWriting: tempFile,
            settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true
            ]
        ) {
            let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: AVAudioFrameCount(samples)
            )!
            buffer.frameLength = AVAudioFrameCount(samples)

            let channelData = buffer.floatChannelData![0]
            for i in 0..<samples {
                channelData[i] = audioData[i]
            }

            try? audioFile.write(from: buffer)

            // Load the generated file
            clickPlayer = try? AVAudioPlayer(contentsOf: tempFile)
            clickPlayer?.prepareToPlay()
            clickPlayer?.volume = 0.8
        }
    }

    // MARK: - Playback

    /// Play the click sound
    func playClick() {
        guard isEnabled else { return }

        // Rewind and play
        clickPlayer?.currentTime = 0
        clickPlayer?.play()
    }

    /// Enable or disable click sound
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}
