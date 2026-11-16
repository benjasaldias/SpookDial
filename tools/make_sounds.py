"""Genera todos los efectos de sonido del juego en audio/sfx/ y los audios de los amigos en audio/clues/.

Reemplaza a los sonidos provisionales (sesión del 10 de noviembre): ahora intentan sonar reales y van con el terror
del juego. La mayoría se sintetiza aquí; lo que la síntesis no logra (el gallo, la oveja, el llanto de guagua y los
gruñidos) sale de grabaciones de dominio público o CC0 que están en audio/source/, con su ficha y sus créditos en
audio/source/creditos.md. Ningún sonido dice palabras (decisión de Benja, 10 de noviembre).

Cada sonido lleva una sonoridad objetivo en LUFS (ITU-R BS.1770) y picos bajo -1 dBFS, así que el balance se decide
aquí y no con el volumen de cada nodo. Todo es determinista: siempre salen los mismos archivos.

Uso, desde la carpeta del proyecto (necesita numpy, scipy y ffmpeg, que están en /usr/bin/python3):
    /usr/bin/python3 tools/make_sounds.py            # todos
    /usr/bin/python3 tools/make_sounds.py sync_clap  # solo los que se nombran
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy as np  # noqa: E402

from sound_lib import (RATE, attack_decay, bandpass, brown, bubble, compress, decay, fade, fit, formants,  # noqa: E402
                       friction, generator, highpass, hump, impulse_train, load, loop_seamless, loudness, lowpass,
                       master, modes, moving_resonance, muffle, pad, peaking, phone, pink, place, radio, resonance, reverb,
                       room_ir, samples, silence, smooth_random, soft_clip, speed, strike, tempo, timeline, white, write)

ROOT = Path(__file__).resolve().parent.parent
SFX = ROOT / "audio" / "sfx"
CLUES = ROOT / "audio" / "clues"
SOURCE = ROOT / "audio" / "source"
CLUE_SECONDS = 3.0

# Los espacios donde suenan las cosas.
CABIN = room_ir(0.7, 0.45, seed=1, damping_hz=5000)               # el cuarto de la cabaña, de madera
HOUSE = room_ir(0.9, 0.6, seed=4, damping_hz=3500)                # una casa vista por dentro
OUTDOORS = room_ir(0.9, 0.6, seed=3, damping_hz=3500, predelay=0.03)
LAKE = room_ir(2.2, 1.8, seed=5, damping_hz=3000, predelay=0.06)  # el agua y los cerros devuelven el sonido
CAVE = room_ir(3.2, 2.8, seed=2, damping_hz=2600, predelay=0.04)

# Modos de vibración (hz, tau en segundos, amplitud) de lo que se golpea.
GLASS = [(95, 0.07, 1.0), (180, 0.05, 0.7), (520, 0.035, 0.45), (1240, 0.025, 0.35), (2620, 0.016, 0.25),
         (4150, 0.009, 0.15)]
DESK = [(190, 0.03, 1.0), (410, 0.022, 0.7), (870, 0.012, 0.5), (1650, 0.006, 0.35), (2900, 0.003, 0.2)]
FLOOR = [(82, 0.06, 1.0), (165, 0.045, 0.7), (330, 0.03, 0.45), (640, 0.015, 0.25)]
RING = [(2350, 0.09, 1.0), (3870, 0.07, 0.7), (5600, 0.05, 0.45), (7350, 0.03, 0.3)]


def source(name, start=None, end=None, edge=0.015):
    """Un tramo de una grabación de audio/source/, con los bordes suavizados."""
    return fade(load(SOURCE / name, start, end), edge, edge * 2)


# --- Audio Sync -----------------------------------------------------------------------------------------------------

def sync_kick():
    """La base, en cada golpe fuerte: un bombo con la mazo al frente."""
    seconds = 0.22
    t = timeline(seconds)
    frequency = 50 + 90 * np.exp(-t / 0.03)
    body = np.sin(2 * np.pi * np.cumsum(frequency) / RATE) * attack_decay(seconds, 0.002, 0.07)
    beater = bandpass(white(seconds, 11), 1500, 6000) * decay(seconds, 0.004)
    return master(fade(soft_clip(body + 1.5 * beater, 1.3), 0, 0.03), -16)


def sync_tick():
    """La base, en los golpes intermedios: un platillo cerrado (seis osciladores metálicos y ruido)."""
    seconds = 0.06
    t = timeline(seconds)
    metal = sum(np.sign(np.sin(2 * np.pi * hz * t)) for hz in (205.3, 304.4, 369.6, 522.7, 540.0, 800.0))
    metal = bandpass(metal, 7000, 12000, 2) * decay(seconds, 0.016)
    air = highpass(white(seconds, 12), 8000) * decay(seconds, 0.01)
    return master(fade(metal + 0.8 * air, 0.0005, 0.01), -18)


def sync_clap():
    """El aplauso del amigo, que llega por su celular: tres golpes de manos muy seguidos y la cola de la pieza."""
    seconds = 0.25
    out = silence(seconds)
    for index, at in enumerate((0.0, 0.011, 0.022)):
        place(out, white(0.02, 20 + index) * decay(0.02, 0.0035), at)
    place(out, white(0.2, 23) * decay(0.2, 0.05), 0.033)
    out = formants(out, [(1150, 1.3, 1.0), (2300, 2.0, 0.5), (650, 1.5, 0.3)])
    out = reverb(out, CABIN, 0.18)
    return master(fade(phone(out, 21), 0, 0.04), -15)


def sync_tap():
    """El golpe de Matías: los nudillos contra el escritorio de madera."""
    seconds = 0.12
    knock = strike(seconds, DESK, contact=0.0015, seed=30, brightness=0.25)
    return master(fade(knock, 0, 0.03), -14)


def chime(notes, spacing, seconds, tau, harsh=False):
    """Las notas del mixer cuando termina una ronda: un timbre analógico, suave, como el de un aparato viejo."""
    out = silence(seconds)
    for index, hz in enumerate(notes):
        length = seconds - index * spacing
        t = timeline(length)
        if harsh:
            tone = sum(np.sin(2 * np.pi * hz * k * (1 + detune) * t) / k ** 1.3
                       for k in range(1, 9) for detune in (-0.004, 0.004))
            tone = lowpass(tone, 1400, 2)
        else:
            tone = np.sin(2 * np.pi * hz * t) + 0.22 * np.sin(4 * np.pi * hz * t) + 0.06 * np.sin(6 * np.pi * hz * t)
        last = index == len(notes) - 1
        place(out, tone * attack_decay(length, 0.004, tau * (1.8 if last else 1.0)), index * spacing)
    return reverb(out, CABIN, 0.12)


def sync_success():
    """Se acierta una ronda: cuatro notas que suben."""
    return master(fade(chime([523.25, 659.25, 783.99, 1046.5], 0.075, 0.4, 0.07), 0, 0.05), -18)


def sync_fail():
    """Se falla una ronda: dos notas graves que bajan, ásperas."""
    return master(fade(chime([233.08, 174.61], 0.18, 0.44, 0.1, harsh=True), 0, 0.05), -18)


# --- Interferencia y ambiente ---------------------------------------------------------------------------------------

def interference_static():
    """Avisa una interferencia: estática de radio con chasquidos, cortes y un silbido que se mueve."""
    seconds = 3.0
    t = timeline(seconds)
    rng = generator(40)
    hiss = bandpass(white(seconds, 41), 250, 6500) * smooth_random(seconds, 42, 30, 0.35, 1.0)
    crackle = impulse_train(seconds, np.sort(rng.uniform(0, seconds, 140)), 43, 0.9)
    crackle = highpass(np.convolve(crackle, np.exp(-np.arange(80) / 12.0), "same"), 1200) * 4
    whistle = np.sin(2 * np.pi * np.cumsum(1900 + 700 * np.sin(2 * np.pi * 0.35 * t) + 25 * np.sin(2 * np.pi * 6 * t))
                     / RATE) * smooth_random(seconds, 44, 2, 0.0, 0.12)
    signal_ = hiss + crackle + whistle
    gate = np.ones_like(t)
    for start in rng.uniform(0.2, 2.6, 9):
        gate[samples(start):samples(start + rng.uniform(0.02, 0.06))] = 0.08
    gate = np.convolve(gate, np.ones(64) / 64, "same")
    out = radio(signal_ * gate, 1.6) * hump(seconds, 0.12, 0.6)
    return master(fade(out, 0.04, 0.4), -16)


def creak(seconds, seed, low=35, high=110):
    """Una madera que cruje: fricción que se pega y se suelta, con la resonancia de una tabla."""
    rate = low + (high - low) * hump(seconds, 0.45, 1.0)
    clicks = friction(seconds, rate, seed, 0.35)
    board = modes(0.03, [(520, 0.012, 1.0), (1180, 0.008, 0.6), (2300, 0.004, 0.3)], seed + 1, 0.05)
    out = np.convolve(clicks, board)[:samples(seconds)]
    return lowpass(out * hump(seconds, 0.4, 0.7), 3200)


def ambient_room():
    """El cuarto de la cabaña, de noche, en bucle de 24 s: el viento afuera (grave, con ráfagas y un silbido por
    las rendijas), un zumbido eléctrico muy bajo, el ventilador del PC y la casa que cruje dos veces. Estéreo."""
    loop, crossfade = 24.0, 2.0
    seconds = loop + crossfade
    channels = []
    for side in range(2):
        seed = 50 + 10 * side
        gust = smooth_random(seconds, seed, 0.22, 0.2, 1.0) ** 1.6
        rumble = lowpass(brown(seconds, seed + 1), 140, 2) * (0.6 + 0.4 * gust)
        wind = bandpass(pink(seconds, seed + 2), 220, 1300) * gust
        gap = moving_resonance(pink(seconds, seed + 3), 600 + 420 * gust, 14) * gust ** 2.2
        fan = bandpass(pink(seconds, seed + 4), 900, 5000)
        channels.append(0.9 * rumble + 0.55 * lowpass(wind, 1800) + 0.9 * gap + 0.02 * fan)
    out = np.stack(channels, axis=1)
    t = timeline(seconds)
    hum = (np.sin(2 * np.pi * 100 * t) + 0.45 * np.sin(2 * np.pi * 200 * t) + 0.2 * np.sin(2 * np.pi * 300 * t))
    out += 0.006 * hum[:, None]
    for at, seed, pan in ((7.3, 70, 0.3), (17.9, 71, 0.75)):
        sound = creak(0.55, seed) * 0.12
        place(out[:, 0], sound * (1 - pan), at)
        place(out[:, 1], sound * pan, at)
    out = reverb(out, room_ir(0.7, 0.45, seed=1, damping_hz=5000, stereo=True), 0.12)
    return master(loop_seamless(out, crossfade), -21)


# --- Screamers del escritorio ---------------------------------------------------------------------------------------

def scare_curtains():
    """Las cortinas se abren o se cierran: la tela que roza y las argollas que corren por el fierro."""
    seconds = 1.2
    rng = generator(80)
    cloth = bandpass(pink(seconds, 81), 300, 5000) * hump(seconds, 0.35, 1.0) * smooth_random(seconds, 82, 16, 0.5, 1)
    rings = silence(seconds)
    for index, at in enumerate(np.sort(rng.uniform(0.08, 0.95, 11))):
        place(rings, strike(0.3, RING, 0.0006, seed=83 + index, jitter=0.08, brightness=0.4), at,
              rng.uniform(0.25, 0.6))
    scrape = bandpass(white(seconds, 84), 1800, 6000) * hump(seconds, 0.3, 1.2)
    out = lowpass(cloth, 4500) + 0.22 * rings / (np.abs(rings).max() + 1e-9) + 0.12 * scrape
    return master(fade(reverb(out, CABIN, 0.15), 0.01, 0.15), -19)


def glass_hit(seconds, seed, contact=0.004, rattle=0.3):
    """Un golpe en el vidrio de la ventana: el vidrio, el marco que suena grave y el vidrio que vibra en el marco."""
    hit = strike(seconds, GLASS, contact, seed=seed, jitter=0.05, brightness=0.35)
    t = timeline(seconds)
    buzz = bandpass(white(seconds, seed + 1), 900, 3500) * decay(seconds, 0.06) * (np.sin(2 * np.pi * 48 * t) > 0)
    return hit + rattle * buzz


def scare_window():
    """La figura se asoma un instante en la ventana: una mano que golpea el vidrio y un chillido."""
    seconds = 1.5
    out = silence(seconds)
    place(out, glass_hit(seconds, 90, contact=0.007, rattle=0.5), 0.0)
    shriek = source("monster_growls.ogg", 19.74, 21.5)
    shriek = speed(shriek, 1.7)
    shriek = peaking(highpass(shriek, 500, 2), 2800, 1.2, 6)
    shriek = soft_clip(shriek / (np.abs(shriek).max() + 1e-9) * 2.5, 2.0) * attack_decay(len(shriek) / RATE, 0.02, 0.4)
    place(out, 0.7 * shriek, 0.05)
    return master(fade(reverb(out, CABIN, 0.25), 0.001, 0.2), -12)


def scare_phone():
    """El celular vibra solo, sobre el escritorio de madera: tres zumbidos."""
    seconds = 1.2
    t = timeline(seconds)
    gate = np.zeros_like(t)
    for start in (0.02, 0.44, 0.86):
        gate[samples(start):samples(start + 0.3)] = 1
    gate = np.convolve(gate, np.ones(samples(0.012)) / samples(0.012), "same")
    spin = 0.85 + 0.15 * np.minimum(1, np.convolve(gate, np.ones(samples(0.05)) / samples(0.05), "same"))
    frequency = 168 * spin * (1 + 0.01 * smooth_random(seconds, 100, 8, -1, 1))
    phase = 2 * np.pi * np.cumsum(frequency) / RATE
    motor = soft_clip(np.sin(phase) * 4, 3)
    chatter = bandpass(white(seconds, 101), 1200, 4500) * (np.sin(phase) > 0.6)
    out = bandpass(motor, 120, 3500) + 0.25 * chatter
    out = peaking(peaking(out, 240, 1.4, 6), 520, 2.0, 3) * gate
    return master(fade(reverb(out, CABIN, 0.1), 0, 0.05), -17)


def scare_lights():
    """Las luces parpadean: el zumbido de la corriente (50 Hz, como en Chile) que se corta y vuelve con chasquidos."""
    seconds = 1.5
    t = timeline(seconds)
    hum = sum(np.sin(2 * np.pi * 100 * k * t) / k ** 0.9 for k in range(1, 30))
    sizzle = highpass(white(seconds, 110), 3000) * np.abs(np.sin(2 * np.pi * 50 * t)) ** 4
    gate = np.zeros_like(t)
    spans = ((0.0, 0.18), (0.26, 0.31), (0.42, 0.7), (0.78, 0.83), (0.9, 0.94), (1.02, 1.5))
    clicks = silence(seconds)
    for index, (start, end) in enumerate(spans):
        gate[samples(start):samples(end)] = 1
        if start > 0:
            place(clicks, strike(0.08, [(3200, 0.02, 1.0), (5100, 0.01, 0.6), (900, 0.015, 0.4)], 0.0004,
                                 seed=111 + index, brightness=0.8), start)
    gate = np.convolve(gate, np.ones(samples(0.004)) / samples(0.004), "same")
    out = (0.4 * lowpass(hum, 4000) + 0.5 * sizzle) * gate + 0.5 * clicks
    return master(fade(reverb(out, CABIN, 0.15), 0.005, 0.25), -17)


def scare_slam():
    """El cuaderno se cierra de golpe: el aire de las hojas, el golpe de la tapa y el escritorio que retumba."""
    seconds = 0.5
    out = silence(seconds)
    place(out, lowpass(pink(0.07, 120), 1500) * hump(0.07, 0.9, 1.0) * 0.4, 0.0)
    place(out, strike(0.44, [(110, 0.06, 1.0), (210, 0.05, 0.7), (380, 0.035, 0.5), (720, 0.02, 0.3)], 0.003,
                      seed=121, brightness=0.7), 0.06)
    place(out, bandpass(white(0.1, 122), 2000, 7000) * decay(0.1, 0.02) * 0.3, 0.06)
    return master(fade(reverb(out, CABIN, 0.3), 0, 0.1), -14)


def scare_ink():
    """La mancha de tinta cae en la página: algo húmedo que se aplasta y unas gotas que saltan."""
    seconds = 0.6
    rng = generator(130)
    out = silence(seconds)
    splat = white(seconds, 131) * decay(seconds, 0.014)
    splat = moving_resonance(splat, 1800 * np.exp(-timeline(seconds) / 0.05) + 450, 3)
    place(out, splat, 0.02)
    place(out, np.sin(2 * np.pi * 90 * timeline(0.2)) * decay(0.2, 0.04) * 0.15, 0.02)
    place(out, bandpass(pink(0.25, 132), 400, 3000) * hump(0.25, 0.15, 1.0) * 0.1, 0.03)
    for _ in range(7):
        place(out, bubble(0.05, rng.uniform(900, 2600), rng.uniform(0.008, 0.015)) * rng.uniform(0.06, 0.16),
              rng.uniform(0.12, 0.5))
    return master(fade(reverb(out, CABIN, 0.1), 0, 0.08), -17)


def breath(seconds, seed, inhale):
    """Un respiro de algo grande: ruido por la garganta abierta. Al exhalar, más grave y con un aleteo húmedo."""
    air = highpass(pink(seconds, seed), 200)
    if inhale:
        sound = formants(air, [(650, 4, 1.0), (1150, 5, 0.7), (2600, 6, 0.35)]) * hump(seconds, 0.65, 1.3)
    else:
        flutter = 1 + 0.6 * np.sin(2 * np.pi * 31 * timeline(seconds) + generator(seed).uniform(0, 6))
        sound = formants(air, [(430, 4, 1.0), (920, 5, 0.6), (2300, 6, 0.2)]) * hump(seconds, 0.25, 1.1) * flutter
    return sound


def scare_creature_breathing():
    """La criatura respira al otro lado del vidrio: tres respiros pesados, con un gruñido ronco al exhalar. En
    bucle: el final empalma con el comienzo."""
    loop, crossfade = 8.0, 0.4
    seconds = loop + crossfade
    out = silence(seconds)
    growl = speed(source("monster_growls_2.ogg", 8.04, 11.41), 0.75)
    cycle = loop / 3
    for index in range(4):
        start = index * cycle + 0.15
        jitter = generator(140 + index).uniform(0.94, 1.06)
        inhale, exhale = 0.95 * jitter, 1.35 * jitter
        place(out, 0.8 * breath(inhale, 141 + index, True), start)
        exhale_sound = breath(exhale, 145 + index, False)
        rasp = fit(lowpass(growl[samples(index * 0.6):], 1400), exhale) * hump(exhale, 0.25, 1.0)
        place(out, exhale_sound + 0.55 * rasp / (np.abs(rasp).max() + 1e-9) * np.abs(exhale_sound).max(),
              start + inhale + 0.1)
    out = peaking(lowpass(out, 2800, 2), 180, 1.0, 3)
    out = reverb(out, CABIN, 0.12)
    return master(loop_seamless(out, crossfade), -20)


def scare_creature_knocks():
    """La criatura golpea el vidrio: tres tandas, cada vez más fuertes, y entre la segunda y la tercera arrastra
    las garras por el vidrio. Los golpes caen en los mismos segundos que antes (sonidos_pendiente.md)."""
    seconds = 7.0
    out = silence(seconds)
    hits = (0.6, 1.1, 2.9, 3.35, 3.8, 5.4, 5.8, 6.2, 6.5)
    volumes = (0.5, 0.5, 0.7, 0.7, 0.7, 1.0, 1.0, 1.0, 1.0)
    for index, (at, volume) in enumerate(zip(hits, volumes)):
        place(out, glass_hit(0.6, 150 + index, contact=0.005, rattle=0.25 + 0.2 * volume), at, volume)
    scrape_seconds = 0.8
    rate = 180 + 260 * hump(scrape_seconds, 0.6, 1.0)
    claws = friction(scrape_seconds, rate, 160, 0.3)
    claws = resonance(claws, 2200, 8) + 0.7 * resonance(claws, 3400, 10) + 0.4 * resonance(claws, 1300, 6)
    place(out, 0.15 * claws * hump(scrape_seconds, 0.5, 1.0) / (np.abs(claws).max() + 1e-9), 4.3)
    return master(reverb(out, CABIN, 0.2), -16)


# --- Alucinaciones --------------------------------------------------------------------------------------------------

def hallucination_knock():
    """Tres golpes en la ventana que no vienen de nada: nudillos, un poco más lejos."""
    seconds = 1.0
    out = silence(seconds)
    for index, at in enumerate((0.08, 0.34, 0.6)):
        place(out, glass_hit(0.4, 170 + index, contact=0.0025, rattle=0.15), at, (0.9, 0.8, 1.0)[index])
    return master(fade(reverb(lowpass(out, 5000), CABIN, 0.3), 0, 0.15), -20)


def hallucination_steps():
    """Pasos lentos sobre el piso de madera, en otra pieza: el taco, la punta y una tabla que cruje."""
    seconds = 2.0
    out = silence(seconds)
    for index, at in enumerate((0.1, 0.6, 1.12, 1.62)):
        place(out, strike(0.4, FLOOR, 0.008, seed=180 + index, brightness=0.15), at, 1.0)
        place(out, strike(0.3, FLOOR, 0.006, seed=190 + index, brightness=0.1), at + 0.09, 0.35)
        if index in (1, 3):
            place(out, creak(0.35, 195 + index, 45, 130), at + 0.05, 0.6)
    return master(fade(reverb(muffle(out, 1800), HOUSE, 0.3), 0, 0.2), -22)


VOWELS = {"a": (800, 1300, 2600), "e": (480, 1900, 2600), "i": (300, 2300, 3000), "o": (500, 950, 2500),
          "u": (330, 800, 2500)}


def hallucination_whisper():
    """Un susurro sin palabras, pegado al oído: sílabas soplada con vocales y eses que no forman nada."""
    seconds = 2.0
    rng = generator(200)
    out = silence(seconds)
    at = 0.08
    for index in range(8):
        vowel = VOWELS["aeiouaeo"[(index * 3) % 8]]
        length = rng.uniform(0.12, 0.2)
        consonant = rng.choice(["s", "sh", "h", "k", "t"])
        if consonant in ("s", "sh"):
            low, high = (4500, 9500) if consonant == "s" else (2000, 5500)
            place(out, bandpass(white(0.08, 201 + index), low, high) * hump(0.08, 0.6, 1.0) * 0.5, at)
            at += 0.06
        elif consonant in ("k", "t"):
            place(out, bandpass(white(0.015, 211 + index), 1500 if consonant == "k" else 3500, 8000)
                  * decay(0.015, 0.004), at)
            at += 0.015
        voiceless = highpass(pink(length, 221 + index), 300)
        sound = formants(voiceless, [(vowel[0], 5, 1.0), (vowel[1], 6, 0.6), (vowel[2], 7, 0.3)])
        place(out, sound * hump(length, 0.35, 1.0), at)
        at += length + rng.uniform(0.02, 0.09)
        if at > seconds - 0.25:
            break
    return master(fade(reverb(out, CABIN, 0.08), 0.01, 0.1), -20)


def hallucination_scratch():
    """Rasguños en la pared: uñas que raspan la madera, tres veces."""
    seconds = 1.5
    out = silence(seconds)
    for index, (at, length) in enumerate(((0.05, 0.38), (0.5, 0.42), (0.98, 0.45))):
        rate = 250 + 380 * hump(length, 0.4, 1.0)
        clicks = friction(length, rate, 230 + index, 0.4)
        nails = np.convolve(clicks, modes(0.01, [(2800, 0.0015, 1.0), (4300, 0.0012, 0.7), (6100, 0.001, 0.4)],
                                          240 + index, 0.1))[:samples(length)]
        grit = bandpass(white(length, 250 + index), 2000, 7500) * 0.45 * smooth_random(length, 260 + index, 40, 0.3, 1)
        place(out, (nails / (np.abs(nails).max() + 1e-9) + grit) * hump(length, 0.3, 0.8), at)
    return master(fade(reverb(lowpass(out, 5500), CABIN, 0.15), 0, 0.1), -21)


# --- La Mano y el flash (Plan 9.1) ---------------------------------------------------------------------------------

def hand_creak():
    """La Mano da un tirón (idea de Benja, 11 de noviembre): algo que se retuerce. Un crujido grave de tendones que se
    estiran, dos chasquidos de nudillos y un roce húmedo de pelo y carne. Es sutil: se oye detrás del cuaderno, pero
    no tapa nada."""
    seconds = 0.45
    out = silence(seconds)
    # Los tendones: fricción lenta que se pega y se suelta, por un cuerpo blando y grave.
    rate = 18 + 55 * hump(0.4, 0.55, 1.2)
    clicks = friction(0.4, rate, 301, 0.45)
    body = modes(0.05, [(170, 0.02, 1.0), (310, 0.014, 0.7), (640, 0.008, 0.35)], 302, 0.08)
    tendons = np.convolve(clicks, body)[:samples(0.4)]
    place(out, lowpass(tendons / (np.abs(tendons).max() + 1e-9), 1800) * hump(0.4, 0.4, 0.8), 0.0)
    # Los nudillos: dos chasquidos secos y cortos.
    for index, at in enumerate((0.11, 0.27)):
        knuckle = strike(0.06, [(1450, 0.006, 1.0), (2600, 0.004, 0.6), (4100, 0.002, 0.35)], 0.0008,
                         seed=303 + index, brightness=0.6)
        place(out, knuckle, at, 0.55 - 0.15 * index)
    # Lo húmedo: un roce de ruido que va y viene.
    wet = bandpass(white(0.4, 305), 280, 1300) * smooth_random(0.4, 306, 22, 0.1, 1.0) * hump(0.4, 0.5, 1.0)
    place(out, wet, 0.02, 0.35)
    return master(fade(reverb(out, CABIN, 0.12), 0.005, 0.08), -26)


def phone_flash():
    """El flash del celular (Plan 9.1): el clic doble del obturador, el zumbido agudo del flash que se carga y
    dispara, y un golpe de aire."""
    seconds = 0.5
    out = silence(seconds)
    for index, at in enumerate((0.0, 0.05)):
        shutter = strike(0.04, [(3100, 0.004, 1.0), (5200, 0.003, 0.7), (7400, 0.002, 0.4)], 0.0005,
                         seed=311 + index, brightness=0.8)
        place(out, shutter, at, 0.9 - 0.3 * index)
    t = timeline(0.38)
    pitch = 2200 + 4800 * (t / 0.38) ** 0.6
    whine = np.sin(2 * np.pi * np.cumsum(pitch) / RATE) * attack_decay(0.38, 0.03, 0.16) * 0.22
    place(out, fade(whine, 0.0, 0.08), 0.04)
    place(out, lowpass(pink(0.12, 313), 900) * attack_decay(0.12, 0.004, 0.035) * 0.6, 0.06)
    return master(fade(reverb(out, CABIN, 0.1), 0.0, 0.06), -17)


# --- La alarma de las entradas del PC (Plan 9.8: pedido de Benja, que suene a alarma) --------------------------------
# Cada amigo tiene su alarma electrónica, distinta de las otras (ya no hacen un acorde). Una entrada en alerta pita cada
# medio segundo, con su luz, así que cada pitido dura menos de un cuarto de segundo. Suenan por el parlante del PC, al
# nivel de los otros sonidos cortos del juego (el aplauso de Audio Sync), mucho más fuerte que la alarma de antes.
ALARM_RMS = -24

def square(frequency, seconds, harmonics=9):
    """Una onda cuadrada de aparato, con sus armónicos impares hasta `harmonics` (así no suena digital ni raspa)."""
    t = timeline(seconds)
    return sum(np.sin(2 * np.pi * frequency * k * t) / k for k in range(1, harmonics + 1, 2))


def pc_speaker(x):
    """El parlante chico del PC: sin graves ni agudos extremos, un poco saturado."""
    return soft_clip(lowpass(highpass(x, 350), 6500), 1.6)


def short_master(x, rms_db, ceiling_db=-1.0):
    """Para los sonidos de menos de 0,4 s, donde la sonoridad en LUFS no sirve: los lleva a un RMS de `rms_db` y limita
    los picos a `ceiling_db`. Así las 3 alarmas suenan igual de fuerte."""
    x = x - x.mean()
    y = x * 10 ** ((rms_db - 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12)) / 20)
    ceiling = 10 ** (ceiling_db / 20)
    peak = np.abs(y).max()
    return y if peak <= ceiling else soft_clip(y / peak * 1.2, 1.2) * ceiling


def alarm_double_beep():
    """León: un doble bip agudo, corto y seco, como un monitor."""
    out = silence(0.22)
    for at in (0.0, 0.11):
        beep = square(2350, 0.075) * attack_decay(0.075, 0.003, 0.06)
        place(out, fade(beep, 0.002, 0.01), at)
    return short_master(fade(reverb(pad(pc_speaker(out), 0.05), CABIN, 0.05), 0.0, 0.03), ALARM_RMS)


def alarm_buzz():
    """Gonzalo: un zumbido grave y áspero, como un timbre de puerta viejo."""
    seconds = 0.2
    t = timeline(seconds)
    tone = square(392, seconds, 15) * (0.75 + 0.25 * np.sign(np.sin(2 * np.pi * 50 * t)))
    tone *= attack_decay(seconds, 0.004, 0.25)
    return short_master(fade(reverb(pad(pc_speaker(fade(tone, 0.002, 0.02)), 0.05), CABIN, 0.05), 0.0, 0.03), ALARM_RMS)


def alarm_trill():
    """Agustín: un trino rápido entre dos notas agudas, nervioso."""
    seconds = 0.2
    t = timeline(seconds)
    frequency = np.where(np.floor(t / 0.025) % 2 == 0, 1650.0, 2150.0)
    tone = np.sign(np.sin(2 * np.pi * np.cumsum(frequency) / RATE)) * 0.6
    tone = lowpass(tone, 7000) * attack_decay(seconds, 0.003, 0.3)
    return short_master(fade(reverb(pad(pc_speaker(fade(tone, 0.002, 0.02)), 0.05), CABIN, 0.05), 0.0, 0.03), ALARM_RMS)


# --- El aviso suave y el golpe de la ola (Plan 9.8) ------------------------------------------------------------------

def chat_notify():
    """El aviso de un mensaje que no es una emergencia: un "pop" suave de dos notas que suben, sin urgencia."""
    out = silence(0.2)
    for index, (frequency, at) in enumerate(((784.0, 0.0), (1175.0, 0.055))):
        t = timeline(0.09)
        note = np.sin(2 * np.pi * frequency * t) + 0.12 * np.sin(2 * np.pi * 2 * frequency * t)
        place(out, note * attack_decay(0.09, 0.004, 0.035), at, 1.0 - 0.2 * index)
    return short_master(fade(reverb(pad(lowpass(out, 5000), 0.1), CABIN, 0.08), 0.0, 0.05), -30)


def wave_stinger():
    """Empieza una ola: un golpe grave con un acorde disonante de cuerdas metálicas que se apaga, tenso y corto."""
    seconds = 1.6
    out = silence(seconds)
    t = timeline(seconds)
    sub = np.sin(2 * np.pi * np.cumsum(58 - 20 * (t / seconds)) / RATE) * attack_decay(seconds, 0.005, 0.45)
    place(out, sub, 0.0, 0.9)
    place(out, lowpass(brown(0.4, 401), 400) * attack_decay(0.4, 0.002, 0.08), 0.0, 0.8)
    for index, frequency in enumerate((311.1, 329.6, 466.2, 698.5)):
        voice = np.sin(2 * np.pi * frequency * t + 0.3 * np.sin(2 * np.pi * (5.5 + index) * t))
        voice += 0.4 * np.sin(2 * np.pi * 2.01 * frequency * t)
        place(out, voice * attack_decay(seconds, 0.01, 0.5 + 0.1 * index), 0.0, 0.18)
    return master(fade(reverb(pad(out, 0.6), CABIN, 0.25), 0.0, 0.3), -18)


# --- Feedback de una respuesta (Plan 9.10: pedido de Benja) ----------------------------------------------------------

def request_correct():
    """Matías completó bien una consulta: dos notas de campanilla que suben, breves y suaves, para no agobiar."""
    out = silence(0.4)
    for index, (frequency, at) in enumerate(((880.0, 0.0), (1318.5, 0.09))):
        t = timeline(0.3)
        note = (np.sin(2 * np.pi * frequency * t) + 0.1 * np.sin(4 * np.pi * frequency * t)
                + 0.25 * np.sin(2 * np.pi * 2.76 * frequency * t) * np.exp(-t / 0.05))
        place(out, note * attack_decay(0.3, 0.004, 0.09 + 0.05 * index), at, 1.0 - 0.15 * index)
    return short_master(fade(reverb(pad(lowpass(out, 6500), 0.1), CABIN, 0.1), 0.0, 0.1), -26)


def photo_shutter():
    """Matías eligió la opción de la calavera (la de mayor riesgo, que da un video): el sonido de una cámara de fotos,
    el golpe seco del espejo y el doble clic de la cortina del obturador. Distinto del flash del celular."""
    out = silence(0.3)
    mirror = strike(0.09, [(240, 0.012, 1.0), (520, 0.008, 0.6), (1100, 0.004, 0.35)], 0.001, seed=321, brightness=0.35)
    place(out, mirror, 0.0, 0.9)
    for index, at in enumerate((0.035, 0.095)):
        click = strike(0.04, [(2900, 0.004, 1.0), (4700, 0.003, 0.7), (6800, 0.002, 0.4)], 0.0005, seed=322 + index,
                       brightness=0.7)
        place(out, click, at, 0.8 - 0.25 * index)
    return short_master(fade(reverb(pad(out, 0.1), CABIN, 0.08), 0.0, 0.05), -22)


# --- Voces de los amigos --------------------------------------------------------------------------------------------

def murmur(seconds, f0, vowel, nasal, seed):
    """Una sílaba murmurada, "mə", que llega por el micrófono barato de un amigo. El chat le cambia la altura con
    cada letra. `nasal` es cuánto de la sílaba queda con la boca cerrada."""
    t = timeline(seconds)
    rng = generator(seed)
    frequency = f0 * (1 + 0.015 * rng.standard_normal(len(t)).cumsum() / np.sqrt(len(t)))
    phase = 2 * np.pi * np.cumsum(frequency) / RATE
    source_ = sum(np.sin(k * phase) / k ** 1.1 for k in range(1, int(4000 / f0)))
    open_mouth = formants(source_, [(vowel[0], 5, 1.0), (vowel[1], 6, 0.5), (vowel[2], 7, 0.25)])
    closed = formants(source_, [(260, 5, 1.0), (1100, 8, 0.12)])
    blend = np.clip((t / seconds - nasal) / 0.2, 0, 1)
    sound = closed * (1 - blend) * 0.7 + open_mouth * blend
    sound = sound * attack_decay(seconds, 0.006, seconds * 0.6)
    return master(fade(radio(sound, 1.8), 0.002, min(0.012, seconds / 3)), -18)


# --- Audios de los amigos: los lugares -----------------------------------------------------------------------------

def crickets(seconds, seed, count, level):
    """Grillos: cada uno con su altura y su ritmo, a distinta distancia."""
    rng = generator(seed)
    out = silence(seconds)
    for index in range(count):
        hz = rng.uniform(3900, 4800)
        period = rng.uniform(0.45, 0.75)
        pulse = np.sin(2 * np.pi * hz * timeline(0.018)) * np.sin(np.pi * timeline(0.018) / 0.018) ** 2
        chirp = silence(0.11)
        for k in range(3):
            place(chirp, pulse, k * 0.032)
        at = rng.uniform(0, period)
        volume = rng.uniform(0.3, 1.0)
        while at < seconds:
            place(out, chirp, at, volume)
            at += period * rng.uniform(0.95, 1.05)
    return level * lowpass(out, 8000)


def wind(seconds, seed, low, high, level, gusts=0.5):
    return level * bandpass(pink(seconds, seed), low, high) * smooth_random(seconds, seed + 1, gusts, 0.3, 1.0)


def night_yard(seed):
    """El patio de la cabaña de noche: grillos y una brisa."""
    return crickets(CLUE_SECONDS, seed, 4, 0.05) + wind(CLUE_SECONDS, seed + 5, 150, 900, 0.35)


def field(seed):
    """El campo abierto: el viento en el pasto y pocos grillos."""
    return wind(CLUE_SECONDS, seed, 500, 4000, 0.1, 0.8) + wind(CLUE_SECONDS, seed + 3, 100, 500, 0.25) + \
        crickets(CLUE_SECONDS, seed + 7, 2, 0.025)


def lake(seed):
    """La orilla del lago: el agua que golpea la orilla y burbujea."""
    rng = generator(seed)
    t = timeline(CLUE_SECONDS)
    swell = (0.5 + 0.5 * np.sin(2 * np.pi * 0.6 * t + rng.uniform(0, 6))) ** 3 * smooth_random(CLUE_SECONDS, seed,
                                                                                                1.5, 0.5, 1)
    out = 0.5 * lowpass(pink(CLUE_SECONDS, seed + 1), 700) * (0.3 + swell)
    out += 0.08 * bandpass(white(CLUE_SECONDS, seed + 2), 1500, 5000) * swell
    for _ in range(18):
        place(out, bubble(0.04, rng.uniform(350, 1200), rng.uniform(0.006, 0.014)) * rng.uniform(0.04, 0.1),
              rng.uniform(0, CLUE_SECONDS))
    return out


def stream_side(seed):
    """Un camino junto a un estero: el agua que corre, lejos, y un grillo."""
    rng = generator(seed)
    out = 0.12 * bandpass(pink(CLUE_SECONDS, seed), 400, 3000) * smooth_random(CLUE_SECONDS, seed + 1, 6, 0.6, 1)
    for _ in range(90):
        place(out, bubble(0.03, rng.uniform(300, 1500), rng.uniform(0.004, 0.01)) * rng.uniform(0.01, 0.04),
              rng.uniform(0, CLUE_SECONDS))
    return lowpass(out, 3000) + crickets(CLUE_SECONDS, seed + 3, 1, 0.02)


def forest(seed):
    """El bosque de Chiloé de noche: el viento en las hojas y gotas que caen de los árboles."""
    rng = generator(seed)
    out = 0.12 * bandpass(pink(CLUE_SECONDS, seed), 1500, 7000) * smooth_random(CLUE_SECONDS, seed + 1, 3, 0.2, 1) ** 2
    out += wind(CLUE_SECONDS, seed + 2, 80, 400, 0.35)
    for _ in range(4):
        place(out, bubble(0.03, rng.uniform(2000, 3500), 0.006) * 0.05, rng.uniform(0, CLUE_SECONDS))
    return out


def house(seed):
    """Adentro de una casa: el zumbido de la corriente, el aire quieto y un reloj."""
    t = timeline(CLUE_SECONDS)
    out = 0.12 * lowpass(pink(CLUE_SECONDS, seed), 300)
    out += 0.006 * (np.sin(2 * np.pi * 100 * t) + 0.4 * np.sin(2 * np.pi * 200 * t))
    for index in range(3):
        place(out, strike(0.05, [(3100, 0.006, 1.0), (4700, 0.004, 0.5)], 0.0003, seed=seed + index) * 0.015,
              0.4 + index)
    return reverb(out, HOUSE, 0.2)


def cave(seed):
    """La entrada de la cueva: un retumbo grave, el viento que gime en la boca y gotas que caen adentro."""
    rng = generator(seed)
    out = 0.08 * lowpass(brown(CLUE_SECONDS, seed), 150)
    out += 0.05 * moving_resonance(pink(CLUE_SECONDS, seed + 1), 300 + 60 * smooth_random(CLUE_SECONDS, seed + 2, 0.5),
                                   10)
    for at in (0.35, 1.4, 2.5):
        place(out, bubble(0.06, rng.uniform(1200, 2000), 0.02, 0.6) * 0.12, at)
    return reverb(out, CAVE, 0.6)


# --- Audios de los amigos: lo que se oye ----------------------------------------------------------------------------

def tue_tue_cry():
    """El grito de dos notas del Tue Tué: áspero, como el de un queltehue, pero lúgubre, y a la distancia."""
    out = silence(0.75)
    for at, length, start, end in ((0.0, 0.2, 1150, 1050), (0.3, 0.32, 1380, 1230)):
        t = timeline(length)
        frequency = np.linspace(start, end, len(t)) * (1 + 0.012 * np.sin(2 * np.pi * 7 * t))
        phase = 2 * np.pi * np.cumsum(frequency) / RATE
        tone = sum(np.sin(k * phase) / k for k in range(1, 6)) * (1 - 0.4 * (np.sin(2 * np.pi * 72 * t) > 0))
        tone = peaking(tone, 2400, 1.0, 5) * attack_decay(length, 0.015, length * 0.7)
        place(out, tone, at)
    return reverb(pad(lowpass(out, 7000), 0.8), OUTDOORS, 0.4)


def weeping_bleat(start, end, seed):
    """Un balido de la grabación, más grave y temblando, como si llorara."""
    bleat = source("sheep_bleating.ogg", start, end, 0.03)
    t = timeline(len(bleat) / RATE)
    sob = 1 - 0.75 * (0.5 + 0.5 * np.sin(2 * np.pi * 6.2 * t + generator(seed).uniform(0, 6))) ** 1.5
    return speed(bleat * sob, 0.9)


def snort(seed):
    """Un bufido fuerte de enojo: aire por la nariz, con el aleteo de las narinas."""
    seconds = 0.35
    air = formants(pink(seconds, seed), [(300, 3, 1.0), (900, 4, 0.6), (2200, 5, 0.4)])
    flap = 1 - 0.7 * (0.5 + 0.5 * np.sin(2 * np.pi * 28 * timeline(seconds)))
    return air * flap * attack_decay(seconds, 0.015, 0.12)


def hoof(seed):
    """Una pata que golpea la tierra."""
    return strike(0.2, [(70, 0.05, 1.0), (140, 0.03, 0.6), (420, 0.01, 0.3)], 0.01, seed=seed, brightness=0.3)


def call_whistle():
    """El silbido del Cuero: dos notas que suben, como alguien que llama desde lejos, del otro lado del agua."""
    out = silence(1.0)
    for at, length, contour in ((0.0, 0.18, (1600, 2200, 2200)), (0.28, 0.5, (1500, 2400, 2100))):
        t = timeline(length)
        frequency = np.interp(t, [0, length * 0.45, length], contour) * (1 + 0.008 * np.sin(2 * np.pi * 5.5 * t))
        tone = np.sin(2 * np.pi * np.cumsum(frequency) / RATE)
        breath_ = bandpass(white(length, 300), 1300, 2800) * 0.08
        place(out, (tone + breath_) * attack_decay(length, 0.03, length * 0.8), at)
    return reverb(pad(lowpass(out, 6000), 1.2), LAKE, 0.55)


def heel(seed):
    """Un taco contra la piedra del camino: seco y agudo."""
    return strike(0.25, [(1850, 0.012, 1.0), (3100, 0.008, 0.6), (4700, 0.005, 0.4), (260, 0.02, 0.5)], 0.0008,
                  seed=seed, jitter=0.04, brightness=0.5)


def squelch(seed):
    """Un paso en el barro: el pie que se hunde, húmedo, y la succión al sacarlo."""
    rng = generator(seed)
    out = silence(0.45)
    place(out, strike(0.2, [(70, 0.06, 1.0), (130, 0.04, 0.6)], 0.015, seed=seed), 0)
    wet = moving_resonance(white(0.12, seed + 1) * decay(0.12, 0.03), np.linspace(900, 300, samples(0.12)), 4)
    place(out, 0.6 * wet, 0.005)
    pull = bandpass(white(0.15, seed + 2), 200, 1500) * hump(0.15, 0.7, 1.0)
    place(out, 0.5 * moving_resonance(pull, np.linspace(300, 1200, samples(0.15)), 5), 0.22)
    for k in range(3):
        place(out, bubble(0.03, rng.uniform(250, 600), 0.01) * 0.25, 0.3 + 0.03 * k)
    return lowpass(out, 2500)


def crunch(seed):
    """Un paso en tierra seca y hojas: muchos crujidos chicos y un golpe sordo."""
    rng = generator(seed)
    out = silence(0.25)
    for at in np.sort(rng.uniform(0, 0.13, 80)) + rng.uniform(0, 0.005):
        grain = white(0.006, int(at * 1e5) + seed) * decay(0.006, 0.0012)
        place(out, grain * rng.uniform(0.2, 1.0), at)
    out = bandpass(out, 1500, 7500)
    place(out, strike(0.15, [(90, 0.03, 1.0), (180, 0.02, 0.5)], 0.01, seed=seed + 1) * 0.35, 0)
    return out


def muffled_crow(seed, ratio):
    """El canto del gallo, apagado, como si saliera de debajo del piso. `ratio` lo acelera sin cambiar su altura."""
    crow = tempo(source("small_rooster_crowing.ogg", 2.66, 4.3), ratio)
    return reverb(pad(muffle(crow, 1000), 0.5), HOUSE, 0.3)


def growl(start, end, ratio=0.85):
    return speed(source("monster_growls.ogg", start, end, 0.03), ratio)


def baby_cry():
    """Un llanto de guagua, lejos, en el fondo de la cueva."""
    cry = source("crying_newborn_baby.ogg", 8.22, 9.61, 0.04)
    return lowpass(cry, 4500)


def stomach_growl(seconds, seed):
    """Unas tripas que suenan (el tutorial, Plan 9.5): un gruñido grave y áspero, como un crujido lento que pasa por un
    cuerpo blando, con aire que se mueve adentro y gorgoteos que burbujean. Sin palabras."""
    rng = generator(seed)
    rate = 18 + 34 * smooth_random(seconds, seed, 3)
    clicks = friction(seconds, rate, seed + 1, 0.45)
    creak = formants(clicks, [(170, 5, 1.0), (310, 6, 0.6), (520, 7, 0.25)])
    air = moving_resonance(brown(seconds, seed + 2), 130 + 170 * smooth_random(seconds, seed + 3, 2), 7)
    out = 0.7 * creak / (np.abs(creak).max() + 1e-9) + 0.9 * air / (np.abs(air).max() + 1e-9)
    for _ in range(int(seconds * 9)):
        place(out, bubble(0.06, rng.uniform(190, 460), rng.uniform(0.012, 0.03)) * rng.uniform(0.25, 0.6),
              rng.uniform(0.05, seconds - 0.1))
    return lowpass(out * hump(seconds, 0.35, 1.1), 1600)


def clue_groups():
    """Los audios que mandan los amigos, por entidad: {nombre del archivo: muestras}. Los de una misma entidad
    comparten el fondo y la ganancia, así que solo cambia lo que hay que distinguir."""
    def mix(background, sounds):
        out = fit(background.copy(), CLUE_SECONDS)
        for sound, at, gain in sounds:
            place(out, sound, at, gain)
        return out

    cry = tue_tue_cry()
    steps_at = (0.15, 0.85, 1.55, 2.25)
    growls = [(growl(0.3, 2.24), 0.05, 0.9), (growl(22.66, 24.2), 2.0, 0.8)]
    cabin = reverb(0.1 * lowpass(pink(CLUE_SECONDS, 58), 500), CABIN, 0.3)
    return [
        {
            # El tutorial: las tripas de Gonzalo, en la cabaña (o nada, si acaba de comer).
            "tutorial_stomach_yes": mix(cabin, [(reverb(pad(stomach_growl(1.3, 59), 0.4), CABIN, 0.2), 0.3, 1.0),
                                                (reverb(pad(stomach_growl(0.9, 61), 0.4), CABIN, 0.2), 1.85, 0.8)]),
            "tutorial_stomach_no": mix(cabin, []),
        },
        {
            "tue_tue_cries_one": mix(night_yard(51), [(cry, 1.0, 1.0)]),
            "tue_tue_cries_three": mix(night_yard(51), [(cry, at, 1.0) for at in (0.2, 1.1, 2.0)]),
            "tue_tue_cries_none": mix(night_yard(51), []),
        },
        {
            "calchona_bleat_tone_weeping": mix(field(52), [(reverb(pad(weeping_bleat(0.6, 1.65, 1), 0.6), OUTDOORS, 0.25),
                                                            0.15, 1.0),
                                                           (reverb(pad(weeping_bleat(5.6, 7.1, 2), 0.6), OUTDOORS, 0.25),
                                                            1.45, 0.9)]),
            "calchona_bleat_tone_snorting": mix(field(52), [(reverb(pad(snort(60 + k), 0.5), OUTDOORS, 0.15), at, 3.5)
                                                            for k, at in enumerate((0.2, 1.0, 1.75))]
                                                + [(hoof(70 + k), at, 1.2) for k, at in enumerate((0.65, 1.45, 2.4))]),
        },
        {
            "cuero_whistle_yes": mix(lake(53), [(call_whistle(), 0.8, 0.8)]),
            "cuero_whistle_no": mix(lake(53), []),
        },
        {
            "viuda_heels_slow": mix(stream_side(54), [(reverb(pad(heel(80 + k), 0.6), OUTDOORS, 0.12), at, 1.0 - 0.1 * (k % 2))
                                                      for k, at in enumerate((0.3, 1.1, 1.9, 2.7))]),
            "viuda_heels_fast": mix(stream_side(54), [(reverb(pad(heel(90 + k), 0.6), OUTDOORS, 0.12), 0.2 + 0.28 * k,
                                                       1.0 - 0.1 * (k % 2)) for k in range(10)]),
        },
        {
            "trauco_ground_muddy": mix(forest(55), [(squelch(100 + k), at, 1.0) for k, at in enumerate(steps_at)]),
            "trauco_ground_dry": mix(forest(55), [(crunch(110 + k), at, 0.8) for k, at in enumerate(steps_at)]),
        },
        {
            "basilisco_crows_once": mix(house(56), [(muffled_crow(1, 1.15), 0.75, 1.0)]),
            "basilisco_crows_twice": mix(house(56), [(muffled_crow(1, 1.3), 0.1, 1.0),
                                                     (muffled_crow(2, 1.3), 1.7, 0.9)]),
        },
        {
            "imbunche_baby_cry_yes": mix(cave(57), [(reverb(pad(s, 1.5), CAVE, 0.5), at, g) for s, at, g in growls]
                                         + [(reverb(pad(baby_cry(), 1.5), CAVE, 0.55, 0.9), 1.15, 1.1)]),
            "imbunche_baby_cry_no": mix(cave(57), [(reverb(pad(s, 1.5), CAVE, 0.5), at, g) for s, at, g in growls
                                                   + [(growl(19.74, 21.5), 1.1, 0.6)]]),
        },
    ]


# --- Todo junto -----------------------------------------------------------------------------------------------------

def clue_sounds():
    """Los audios de los amigos ya pasados por el celular: la ganancia de cada entidad la fija el más fuerte de
    sus audios, que queda en -18 LUFS."""
    result = {}
    for group in clue_groups():
        processed = {name: phone(sound, 7) for name, sound in group.items()}
        loudest = max(loudness(sound) for sound in processed.values())
        for name, sound in processed.items():
            gained = sound * 10 ** ((-18 - loudest) / 20)
            result[name] = master(fade(gained, 0.04, 0.2), loudness(gained))
    return result


SFX_SOUNDS = {
    "sync_kick": sync_kick,
    "sync_tick": sync_tick,
    "sync_clap": sync_clap,
    "sync_tap": sync_tap,
    "sync_success": sync_success,
    "sync_fail": sync_fail,
    "interference_static": interference_static,
    "ambient_room": ambient_room,
    "scare_curtains": scare_curtains,
    "scare_window": scare_window,
    "scare_phone": scare_phone,
    "scare_lights": scare_lights,
    "scare_slam": scare_slam,
    "scare_ink": scare_ink,
    "scare_creature_breathing": scare_creature_breathing,
    "scare_creature_knocks": scare_creature_knocks,
    "hallucination_knock": hallucination_knock,
    "hallucination_steps": hallucination_steps,
    "hallucination_whisper": hallucination_whisper,
    "hallucination_scratch": hallucination_scratch,
    "hand_creak": hand_creak,
    "phone_flash": phone_flash,
    # Cada amigo con su alarma (Plan 9.8): un doble bip, un zumbido y un trino.
    "alarm_leon": alarm_double_beep,
    "alarm_gonzalo": alarm_buzz,
    "alarm_agustin": alarm_trill,
    "chat_notify": chat_notify,
    "wave_stinger": wave_stinger,
    "request_correct": request_correct,
    "photo_shutter": photo_shutter,
    # León: tono medio; Gonzalo: grave y redondo; Agustín: agudo y nasal.
    "voice_leon": lambda: murmur(0.05, 135, VOWELS["a"], 0.3, 1),
    "voice_gonzalo": lambda: murmur(0.066, 100, VOWELS["o"], 0.35, 2),
    "voice_agustin": lambda: murmur(0.034, 172, VOWELS["e"], 0.5, 3),
}


def main(names):
    for name, make in SFX_SOUNDS.items():
        if not names or name in names:
            write(SFX / (name + ".wav"), make())
            print("sfx  ", name)
    if not names or any(name not in SFX_SOUNDS for name in names):
        for name, sound in clue_sounds().items():
            if not names or name in names:
                write(CLUES / (name + ".wav"), sound)
                print("clue ", name)


if __name__ == "__main__":
    main(sys.argv[1:])
