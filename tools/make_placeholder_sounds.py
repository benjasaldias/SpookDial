"""Genera los sonidos provisionales de los planes 6 y 7 en audio/sfx/ (WAV mono de 16 bits a 44 100 Hz).

Son de relleno, hasta que Benja elija los definitivos (Plan 9):
- Plan 6: la base y los aplausos de Audio Sync, el golpe de Matías, el resultado de una ronda y la estática
  que anuncia una interferencia;
- Plan 7: el sonido ambiente del cuarto, uno por screamer y los cuatro de las alucinaciones;
- 4 de noviembre: la respiración y los golpes de la criatura de la ventana, que reemplazan al grito del jumpscare.
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


def breathing():
    """La criatura de la ventana: 8 s de respiración pesada y ronca, tres inspiraciones y tres exhalaciones."""
    white, samples, low, lower, seconds = noise(31), [], 0.0, 0.0, 8.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.12 * (white() - low)
        lower += 0.25 * (low - lower)
        cycle = (t % 2.6) / 2.6
        # Inspira rápido y más agudo, y exhala lento y más grave.
        if cycle < 0.4:
            level = math.sin(math.pi * cycle / 0.4) ** 1.5
            tone = 5.0 * low
        else:
            level = 0.8 * math.sin(math.pi * (cycle - 0.4) / 0.6) ** 1.5
            tone = 8.0 * lower
        rasp = 0.7 + 0.3 * math.sin(2 * math.pi * 31 * t)
        fade = min(t / 0.3, 1.0, (seconds - t) / 0.4)
        samples.append(0.6 * tone * level * rasp * fade)
    return samples


def knocks():
    """La criatura golpea el vidrio: 7 s con tres tandas de golpes pesados, cada vez más fuertes."""
    white, samples, seconds = noise(32), [], 7.0
    hits = (0.6, 1.1, 2.9, 3.35, 3.8, 5.4, 5.8, 6.2, 6.5)
    volumes = (0.5, 0.5, 0.7, 0.7, 0.7, 1.0, 1.0, 1.0, 1.0)
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = 0.0
        for start, volume in zip(hits, volumes):
            if t >= start:
                local = t - start
                value += volume * (math.sin(2 * math.pi * 95 * local) * math.exp(-local * 28)
                                   + 0.35 * math.sin(2 * math.pi * 640 * local) * math.exp(-local * 120)
                                   + 0.25 * white() * math.exp(-local * 160))
        samples.append(0.8 * value)
    return samples


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


def noise(seed):
    """Ruido blanco que siempre sale igual."""
    rng = random.Random(seed)
    return lambda: rng.uniform(-1, 1)


def ambient():
    """Sonido ambiente del cuarto, 8 s que se repiten: viento grave que sube y baja, y un zumbido eléctrico."""
    white, samples, low, lower, seconds = noise(11), [], 0.0, 0.0, 8.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.02 * (white() - low)
        lower += 0.1 * (low - lower)
        gust = 0.6 + 0.4 * math.sin(2 * math.pi * t / seconds) * math.sin(2 * math.pi * 3 * t / seconds)
        hum = 0.03 * math.sin(2 * math.pi * 50 * t) + 0.015 * math.sin(2 * math.pi * 100 * t)
        fade = min(t / 0.5, 1.0, (seconds - t) / 0.5)
        samples.append((3.0 * lower * gust + hum) * fade)
    return samples


def rustle():
    """La cortina: roce de tela, ráfagas de ruido que suben y bajan."""
    white, samples, last_x, last_y, seconds = noise(12), [], 0.0, 0.0, 1.2
    for i in range(int(seconds * RATE)):
        t = i / RATE
        x = white()
        last_y, last_x = 0.8 * (last_y + x - last_x), x
        swish = abs(math.sin(2 * math.pi * 2.5 * t)) ** 2
        samples.append(0.5 * last_y * swish * math.exp(-t * 1.5))
    return samples


def sting():
    """La figura de la ventana: un golpe grave y un chillido que sube."""
    white, samples, phase, seconds = noise(13), [], 0.0, 1.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        boom = 0.8 * math.sin(2 * math.pi * 48 * t) * math.exp(-t * 4)
        phase += 2 * math.pi * (900 + 500 * t / seconds + 25 * math.sin(2 * math.pi * 7 * t)) / RATE
        screech = 0.3 * (math.sin(phase) + 0.4 * math.sin(2.01 * phase)) * min(t / 0.05, 1.0) * math.exp(-t * 1.8)
        samples.append(boom + screech + 0.05 * white() * math.exp(-t * 3))
    return samples


def buzz():
    """El celular vibra: tres zumbidos graves."""
    samples, seconds, partials = [], 1.2, ((160, 1.0), (320, 0.5), (480, 0.3))
    for i in range(int(seconds * RATE)):
        t = i / RATE
        on = (t % 0.4) < 0.3
        tone = sum(volume * math.sin(2 * math.pi * frequency * t) for frequency, volume in partials)
        samples.append(0.35 * tone if on else 0.0)
    return samples


def flicker():
    """Las luces parpadean: zumbido eléctrico que se corta, con chasquidos."""
    white, rng, samples, seconds = noise(14), random.Random(15), [], 1.5
    cut, crackle = False, 0.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        if i % 2205 == 0:
            cut = rng.random() < 0.4
        if rng.random() < 0.003:
            crackle = 1.0
        crackle *= 0.995
        hum = sum(math.sin(2 * math.pi * 100 * h * t) / h for h in (1, 2, 3, 5))
        samples.append((0.0 if cut else 0.25 * hum) + 0.5 * crackle * white())
    return samples


def slam():
    """El cuaderno se cierra de golpe: un golpe seco y grave."""
    white, samples, seconds = noise(16), [], 0.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        samples.append(0.7 * math.sin(2 * math.pi * 70 * t) * math.exp(-t * 18) + 0.3 * white() * math.exp(-t * 60))
    return samples


def splat():
    """La mancha de tinta: algo húmedo que se aplasta y gotea."""
    white, samples, low, seconds = noise(17), [], 0.0, 0.6
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.15 * (white() - low)
        drips = sum(math.exp(-(t - start) * 40) for start in (0.25, 0.38, 0.47) if t >= start)
        samples.append(1.2 * low * (math.exp(-t * 14) + 0.4 * drips))
    return samples


def scream():
    """El jumpscare: un grito disonante y fuerte."""
    white, samples, phases, seconds = noise(18), [], [0.0, 0.0, 0.0], 1.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = 0.0
        for index, base in enumerate((520, 555, 740)):
            phases[index] += 2 * math.pi * (base + 40 * math.sin(2 * math.pi * (6 + index) * t)) / RATE
            value += 2 * (phases[index] / (2 * math.pi) % 1.0) - 1
        envelope = min(t / 0.02, 1.0) * (1.0 if t < 1.0 else (seconds - t) / 0.5)
        samples.append((0.22 * value + 0.25 * white()) * envelope)
    return samples


def knock():
    """Alucinación: tres golpes en la ventana."""
    samples, seconds = [], 1.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        value = 0.0
        for start in (0.0, 0.25, 0.5):
            if t >= start:
                local = t - start
                value += math.sin(2 * math.pi * 130 * local) * math.exp(-local * 35)
                value += 0.3 * math.sin(2 * math.pi * 900 * local) * math.exp(-local * 200)
        samples.append(0.8 * value)
    return samples


def steps():
    """Alucinación: cuatro pasos lentos sobre madera."""
    white, samples, low, seconds = noise(19), [], 0.0, 2.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        low += 0.2 * (white() - low)
        value = 0.0
        for start in (0.0, 0.5, 1.0, 1.5):
            if t >= start:
                local = t - start
                value += 0.6 * math.sin(2 * math.pi * 85 * local) * math.exp(-local * 25)
                value += 0.6 * low * math.exp(-local * 30)
        samples.append(value)
    return samples


def whisper():
    """Alucinación: un susurro sin palabras, ruido agudo con sílabas."""
    white, samples, last_x, last_y, seconds = noise(20), [], 0.0, 0.0, 2.0
    for i in range(int(seconds * RATE)):
        t = i / RATE
        x = white()
        last_y, last_x = 0.6 * (last_y + x - last_x), x
        syllables = max(math.sin(2 * math.pi * 4.5 * t) * math.sin(2 * math.pi * 1.3 * t + 1.0), 0.0)
        fade = min(t / 0.2, 1.0, (seconds - t) / 0.3)
        samples.append(0.7 * last_y * syllables * fade)
    return samples


def scratch():
    """Alucinación: rasguños en la pared, trazos de ruido áspero."""
    white, samples, last_x, last_y, seconds = noise(21), [], 0.0, 0.0, 1.5
    for i in range(int(seconds * RATE)):
        t = i / RATE
        x = white()
        last_y, last_x = 0.7 * (last_y + x - last_x), x
        stroke = (t % 0.5) / 0.5
        grain = 0.5 + 0.5 * math.sin(2 * math.pi * 60 * t)
        samples.append(0.6 * last_y * math.sin(math.pi * stroke) * grain)
    return samples


if __name__ == "__main__":
    write("sync_kick", kick())
    write("sync_tick", tick())
    write("sync_clap", clap())
    write("sync_tap", tap())
    write("sync_success", notes([523.25, 659.25, 783.99, 1046.5], 0.1, 9, 0.35))
    write("sync_fail", notes([233.08, 174.61], 0.22, 6, 0.4))
    write("interference_static", static())
    write("ambient_room", ambient())
    write("scare_curtains", rustle())
    write("scare_window", sting())
    write("scare_phone", buzz())
    write("scare_lights", flicker())
    write("scare_slam", slam())
    write("scare_ink", splat())
    write("scare_jumpscare", scream())
    write("scare_creature_breathing", breathing())
    write("scare_creature_knocks", knocks())
    write("hallucination_knock", knock())
    write("hallucination_steps", steps())
    write("hallucination_whisper", whisper())
    write("hallucination_scratch", scratch())
    print("Sonidos provisionales en", OUT)
