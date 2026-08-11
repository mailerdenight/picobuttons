@preconcurrency import AVFoundation
import Observation

@MainActor
@Observable
final class PlaybackService: NSObject, AVAudioPlayerDelegate {
    var activeSoundIDs = Set<Sound.ID>()
    var playbackRate: Float = 1
    private(set) var loopingSoundIDs = Set<Sound.ID>()
    /// Four prepared voices per sound keep rapid taps polyphonic without disk I/O.
    private let voicesPerSound = 4
    private var players = [Sound.ID: [AVAudioPlayer]]()
    private var tempoMultipliers = [Sound.ID: Float]()
    private var soundIDsByPlayer = [ObjectIdentifier: Sound.ID]()

    func warmUp(_ sounds: [Sound]) {
        guard activateAudio() else { return }
        for sound in sounds where players[sound.id] == nil { prepareVoices(for: sound) }
    }

    func play(_ sound: Sound, repeating: Bool) {
        guard activateAudio(), let player = preparedPlayer(for: sound, repeating: repeating) else { return }

        if repeating, loopingSoundIDs.contains(sound.id) {
            stopLoop(sound.id)
            return
        }

        player.stop()
        player.currentTime = 0
        player.numberOfLoops = repeating ? -1 : 0
        player.volume = 1
        player.enableRate = true
        player.rate = playbackRate * sound.tempoMultiplier
        player.prepareToPlay()
        guard player.play() else { return }
        activeSoundIDs.insert(sound.id)
        if repeating { loopingSoundIDs.insert(sound.id) }
    }

    func stop() {
        players.values.flatMap { $0 }.forEach { $0.stop() }
        activeSoundIDs.removeAll()
        loopingSoundIDs.removeAll()
    }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        for (soundID, voices) in players {
            let multiplier = tempoMultipliers[soundID, default: 1]
            for player in voices where player.isPlaying { player.rate = rate * multiplier }
        }
    }

    func setLooping(_ isLooping: Bool) {
        if !isLooping { stopAllLoops() }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let playerID = ObjectIdentifier(player)
        Task { @MainActor [weak self] in self?.finishPlayback(for: playerID) }
    }

    private func preparedPlayer(for sound: Sound, repeating: Bool) -> AVAudioPlayer? {
        if players[sound.id] == nil { prepareVoices(for: sound) }
        guard let voices = players[sound.id], !voices.isEmpty else { return nil }
        // Voice zero is reserved for the sole loop; one-shot taps take the next idle voice.
        if repeating { return voices[0] }
        return voices.dropFirst().first(where: { !$0.isPlaying }) ?? voices.dropFirst().first ?? voices[0]
    }

    private func prepareVoices(for sound: Sound) {
        guard let url = sound.resourceURL else { return }
        tempoMultipliers[sound.id] = sound.tempoMultiplier
        do {
            let voices = try (0..<voicesPerSound).map { _ in
                let player = try AVAudioPlayer(contentsOf: url)
                player.enableRate = true
                player.delegate = self
                player.prepareToPlay()
                soundIDsByPlayer[ObjectIdentifier(player)] = sound.id
                return player
            }
            players[sound.id] = voices
        } catch {
            print("Unable to load \(sound.id): \(error.localizedDescription)")
        }
    }

    private func stopLoop(_ soundID: Sound.ID) {
        players[soundID]?.first?.stop()
        loopingSoundIDs.remove(soundID)
        refreshActiveSoundIDs()
    }

    private func stopAllLoops() {
        for soundID in loopingSoundIDs { players[soundID]?.first?.stop() }
        loopingSoundIDs.removeAll()
        refreshActiveSoundIDs()
    }

    private func finishPlayback(for playerID: ObjectIdentifier) {
        guard let soundID = soundIDsByPlayer[playerID] else { return }
        refreshActiveSoundIDs()
        loopingSoundIDs.remove(soundID)
    }

    private func refreshActiveSoundIDs() {
        activeSoundIDs = Set(players.compactMap { soundID, voices in
            voices.contains(where: \.isPlaying) ? soundID : nil
        })
    }

    private func activateAudio() -> Bool {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            return true
        } catch {
            print("Unable to activate audio: \(error.localizedDescription)")
            return false
        }
    }
}

private extension Sound {
    var resourceURL: URL? { Bundle.main.url(forResource: resourceID, withExtension: "wav") }
}
