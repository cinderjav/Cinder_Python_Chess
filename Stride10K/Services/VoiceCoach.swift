import AVFoundation

/// Speaks workout cues over (and briefly ducking) whatever the user is listening to.
@MainActor
final class VoiceCoach: NSObject, AVSpeechSynthesizerDelegate {
    var isEnabled = true

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Configures the audio session for spoken prompts. Call once before a workout.
    func prepare() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .voicePrompt,
            options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
        )
    }

    func say(_ text: String) {
        guard isEnabled, !text.isEmpty else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        deactivateIfIdle()
    }

    private func deactivateIfIdle() {
        guard !synthesizer.isSpeaking else { return }
        // Lets other audio return to full volume.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.deactivateIfIdle() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.deactivateIfIdle() }
    }
}
