"""Genera los sonidos provisionales del Plan 6 en audio/sfx/ (WAV mono de 16 bits a 44 100 Hz).

Son de relleno, hasta que Benja elija los definitivos (Plan 9): la base y los aplausos de Audio Sync,
el golpe de Matías, el resultado de una ronda y la estática que anuncia una interferencia.
Siempre generan los mismos archivos.

Uso, desde la carpeta del proyecto: python3 -I tools/make_placeholder_sounds.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "audio" / "sfx"


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    frames = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples)
    with wave.open(str(OUT / (name + ".wav")), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)


def kick():
    """Bombo de la base: un tono que cae de 155 a 45 Hz, con un golpe al comienzo."""
    samples, phase = [], 0.0
    for i in range(int(0.22 * RATE)):
        t = i / RATE
        phase += 2 * math.pi * (45 + 110 * math.exp(-t * 30)) / RATE
        samples.append(0.9 * math.sin(phase) * math.exp(-t * 14) + 0.25 * math.sin(3 * phase) * math.exp(-t * 400))
    return samples


def tick():
    """Platillo cerrado de la base: ruido agudo y corto."""
    rng, samples, last_x, last_y = random.Random(2), [], 0.0, 0.0
    for i in range(int(0.06 * RATE)):
        x = rng.uniform(-1, 1)
        last_y, last_x = 0.86 * (last_y + x - last_x), x
        samples.append(0.5 * last_y * math.exp(-i / RATE * 70))
    return samples


def clap():
    """Aplauso del amigo: tres golpes de ruido muy seguidos y una cola corta."""
    rng, samples, low, last_x, last_y = random.Random(3), [], 0.0, 0.0, 0.0
    for i in range(int(0.25 * RATE)):
        t = i / RATE
        envelope = max(math.exp(-(t - start) * 120) for start in (0.0, 0.011, 0.022) if t >= start)
        if t >= 0.03:
            envelope = max(envelope, 0.6 * math.exp(-(t - 0.03) * 22))
        low += 0.35 * (rng.uniform(-1, 1) - low)
        last_y, last_x = 0.9 * (last_y + low - last_x), low
        samples.append(1.6 * last_y * envelope)
    return samples


def tap():
    """Golpe de Matías: un bloque de madera, distinto del aplauso."""
    samples = []
    for i in range(int(0.12 * RATE)):
        t = i / RATE
        tone = 0.7 * math.sin(2 * math.pi * 820 * t) + 0.25 * math.sin(2 * math.pi * 1640 * t)
        samples.append(0.8 * tone * math.exp(-t * 45))
    return samples


def notes(frequencies, seconds, decay, volume):
    """Notas seguidas con un timbre de consola (onda casi cuadrada)."""
    samples = []
    for frequency in frequencies:
        for i in range(int(seconds * RATE)):
            t = i / RATE
            wave_value = sum(math.sin(2 * math.pi * frequency * harmonic * t) / harmonic for harmonic in (1, 3, 5))
            samples.append(volume * wave_value * math.exp(-t * decay))
    return samples


def static():
    """Estática de 3 s que anuncia una interferencia: ruido con chasquidos, que aparece y se va."""
    rng, samples, low, crackle, seconds = random.Random(7), [], 0.0, 0.0, 3.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        if rng.random() < 0.002:
            crackle = rng.uniform(0.3, 1.0)
        crackle *= 0.9995
        low += 0.5 * (rng.uniform(-1, 1) - low)
        fade = min(t / 0.2, 1.0, (seconds - t) / 0.3)
        samples.append(0.7 * low * (0.25 + 0.5 * crackle) * fade)
    return samples


if __name__ == "__main__":
    write("sync_kick", kick())
    write("sync_tick", tick())
    write("sync_clap", clap())
    write("sync_tap", tap())
    write("sync_success", notes([523.25, 659.25, 783.99, 1046.5], 0.1, 9, 0.35))
    write("sync_fail", notes([233.08, 174.61], 0.22, 6, 0.4))
    write("interference_static", static())
    print("Sonidos provisionales en", OUT)
