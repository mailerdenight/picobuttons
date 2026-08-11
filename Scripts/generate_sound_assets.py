#!/usr/bin/env python3
"""Generate the original synthesized sounds bundled by Pico Buttons."""

from math import pi, sin
from pathlib import Path
from struct import pack
import wave

SAMPLE_RATE = 44_100
OUTPUT = Path(__file__).parents[1] / "PicoButtons" / "Resources" / "Sounds"


def repeat(sequence, count):
    return sequence * count


def sweep(start, stop, step, milliseconds):
    values = []
    frequency = start
    while (step > 0 and frequency <= stop) or (step < 0 and frequency >= stop):
        values.append((frequency, milliseconds))
        frequency += step
    return values


PATTERNS = {
    "siren": [(2217, 97), (2150, 110), (2100, 110), (2050, 110)],
    "proximity": repeat([(800, 60), (0, 20), (600, 60), (0, 20)], 6),
    "bomb": sweep(2300, 580, -50, 40) + [item for frequency in sweep(180, 20, -10, 0) for item in [(frequency[0], 20), (frequency[0] + 10, 20), (max(20, frequency[0] - 10), 20), (frequency[0] + 10, 20)]],
    "pew": repeat([(180, 20), (190, 20), (90, 20), (90, 20)] + sweep(2200, 800, -100, 20), 3),
    "toy1": repeat([(1000, 200), (800, 200)], 4),
    "phone": repeat([(800, 30), (600, 30)], 6),
    "toy2": repeat(sweep(800, 980, 60, 15) + sweep(1000, 820, -60, 15), 5),
    "machinegun": [(200, 10), (250, 10), (100, 10), (50, 10)],
    "coin": [(1200, 80), (1600, 80), (2000, 80)],
    "start": [(440, 120), (660, 120), (880, 120), (1320, 240)],
    "warp": sweep(240, 1920, 50, 20),
    "powerup": sweep(400, 1600, 100, 35),
    "gameover": [(660, 180), (520, 180), (440, 180), (330, 180)],
    "ufo": repeat(sweep(480, 900, 70, 20) + sweep(900, 480, -70, 20), 4),
    "radar": repeat([(880, 70), (0, 130)], 3),
    "laser": sweep(1900, 300, -80, 18),
}


def render(name, segments):
    samples = []
    phase = 0.0
    for frequency, milliseconds in segments:
        frames = max(1, int(SAMPLE_RATE * milliseconds / 1000))
        for _ in range(frames):
            if frequency == 0:
                samples.append(0)
                continue
            phase += frequency / SAMPLE_RATE
            samples.append(22000 if sin(2 * pi * phase) >= 0 else -22000)

    fade = min(180, len(samples) // 2)
    for index in range(fade):
        samples[index] = int(samples[index] * index / fade)
        samples[-1 - index] = int(samples[-1 - index] * index / fade)

    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pack("<%dh" % len(samples), *samples))


OUTPUT.mkdir(parents=True, exist_ok=True)
for sound_name, sound_segments in PATTERNS.items():
    render(sound_name, sound_segments)
