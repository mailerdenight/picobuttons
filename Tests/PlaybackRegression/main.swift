import Foundation

// Deterministic audio doubles: exercise the production PlaybackService without
// an audio device. Real AVFoundation and audible output require an iOS check.
protocol AVAudioPlayerDelegate: AnyObject {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
}

@MainActor
final class AVAudioPlayer: NSObject {
    static var created: [AVAudioPlayer] = []
    weak var delegate: AVAudioPlayerDelegate?
    var isPlaying = false
    var currentTime: Double = 0
    var numberOfLoops = 0
    var volume: Float = 1
    var enableRate = false
    var rate: Float = 1

    init(contentsOf url: URL) throws {
        super.init()
        Self.created.append(self)
    }

    func prepareToPlay() {}
    func play() -> Bool { isPlaying = true; return true }
    func stop() { isPlaying = false }
    func finish() {
        isPlaying = false
        delegate?.audioPlayerDidFinishPlaying(self, successfully: true)
    }
}

@MainActor
final class AVAudioSession {
    enum Category { case playback }
    enum Mode { case `default` }
    private static let instance = AVAudioSession()
    static func sharedInstance() -> AVAudioSession { instance }
    func setCategory(_ category: Category, mode: Mode, options: [Int]) throws {}
    func setActive(_ active: Bool) throws {}
}

@main
struct PlaybackRegression {
    @MainActor
    static func main() async {
        let sounds = Array(Sound.library.prefix(3))
        let a = sounds[0], b = sounds[1], c = sounds[2]
        let service = PlaybackService()
        service.warmUp(sounds)
        precondition(AVAudioPlayer.created.count == 12, "Each sound needs four voices")
        let aLoop = AVAudioPlayer.created[0], aShot = AVAudioPlayer.created[1]
        let bLoop = AVAudioPlayer.created[4], bShot = AVAudioPlayer.created[5]
        let cLoop = AVAudioPlayer.created[8]

        service.play(a, repeating: true)
        service.play(b, repeating: true)
        service.play(c, repeating: true)
        precondition(!aLoop.isPlaying && !bLoop.isPlaying && cLoop.isPlaying)
        precondition(service.loopingSoundIDs == [c.id])
        precondition(service.activeSoundIDs == [c.id])
        print("PASS: A → B → C replaces the previous loop")

        service.play(c, repeating: true)
        precondition(!cLoop.isPlaying && service.loopingSoundIDs.isEmpty)
        precondition(service.activeSoundIDs.isEmpty)
        print("PASS: tapping the same loop stops it")

        service.play(a, repeating: false)
        service.play(a, repeating: true)
        precondition(aShot.isPlaying && aLoop.isPlaying)
        aShot.finish()
        await drainCallbacks()
        precondition(aLoop.isPlaying && service.loopingSoundIDs == [a.id])
        precondition(service.activeSoundIDs == [a.id])
        service.play(a, repeating: true)
        precondition(!aLoop.isPlaying && service.loopingSoundIDs.isEmpty)
        print("PASS: one-shot completion preserves the same sound's loop and tap-to-stop")

        service.play(a, repeating: true)
        service.play(a, repeating: false)
        service.play(b, repeating: false)
        service.play(b, repeating: true)
        precondition(!aLoop.isPlaying && aShot.isPlaying && bShot.isPlaying && bLoop.isPlaying)
        precondition(service.loopingSoundIDs == [b.id])
        precondition(service.activeSoundIDs == [a.id, b.id])
        aShot.finish()
        await drainCallbacks()
        precondition(service.loopingSoundIDs == [b.id] && service.activeSoundIDs == [b.id])
        print("PASS: loop replacement leaves one-shots playing")

        service.play(b, repeating: true)
        precondition(!bLoop.isPlaying && bShot.isPlaying)
        precondition(service.loopingSoundIDs.isEmpty && service.activeSoundIDs == [b.id])
        print("PASS: tapping the loop stops only its reserved voice")

        service.play(b, repeating: true)
        service.setLooping(false)
        precondition(!bLoop.isPlaying && bShot.isPlaying && service.loopingSoundIDs.isEmpty)
        service.stop()
        precondition(AVAudioPlayer.created.allSatisfy { !$0.isPlaying })
        precondition(service.activeSoundIDs.isEmpty && service.loopingSoundIDs.isEmpty)
        print("PASS: loop-off preserves one-shots; STOP stops all voices")

        service.play(a, repeating: true)
        aLoop.finish()
        // Its queued completion must not erase a replacement loop on that voice.
        service.play(b, repeating: true)
        service.play(a, repeating: true)
        await drainCallbacks()
        precondition(aLoop.isPlaying && service.loopingSoundIDs == [a.id])
        aLoop.finish()
        await drainCallbacks()
        precondition(service.loopingSoundIDs.isEmpty && service.activeSoundIDs.isEmpty)
        print("PASS: delayed loop callbacks preserve reused voices; finished loops clear state")
    }

    @MainActor
    static func drainCallbacks() async {
        for _ in 0..<20 { await Task.yield() }
    }
}
