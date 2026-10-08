#!/usr/bin/env python3
"""Run production playback logic with audio doubles (Swift 6, macOS or Linux).

Run: python3 Scripts/test_playback_regression.py
Only the AVFoundation import is removed in a temporary copy. PlaybackService
and Sound otherwise compile unchanged. This does not verify real audio output.
"""
import pathlib
import shutil
import subprocess
import tempfile


def main():
    root = pathlib.Path(__file__).resolve().parents[1]
    compiler = shutil.which("swiftc")
    if compiler is None:
        raise SystemExit("Swift 6 compiler is required; install Xcode or Swift first.")
    with tempfile.TemporaryDirectory(prefix="pico-playback-tests-") as directory:
        build = pathlib.Path(directory)
        source = (root / "PicoButtons/Services/PlaybackService.swift").read_text()
        source = source.replace("@preconcurrency import AVFoundation\n", "import Foundation\n", 1)
        service = build / "PlaybackService.swift"
        service.write_text(source)
        # Bundle.main resolves these adjacent resources in the command-line test.
        for wav in (root / "PicoButtons/Resources/Sounds").glob("*.wav"):
            shutil.copy2(wav, build / wav.name)
        executable = build / "PlaybackRegression"
        subprocess.run([
            compiler, "-swift-version", "6", "-parse-as-library",
            str(root / "Tests/PlaybackRegression/main.swift"),
            str(root / "PicoButtons/Models/Sound.swift"), str(service),
            "-o", str(executable),
        ], check=True)
        subprocess.run([str(executable)], cwd=build, check=True)


if __name__ == "__main__":
    main()
