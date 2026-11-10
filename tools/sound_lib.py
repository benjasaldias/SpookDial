"""Herramientas de sonido para tools/make_sounds.py: ruido, filtros, resonancias, reverberación, el filtro del
celular, la sonoridad (LUFS, ITU-R BS.1770) y la lectura de las grabaciones de audio/source/.

Necesita numpy, scipy y ffmpeg. Todo es determinista: la misma semilla da siempre el mismo sonido.
"""
import subprocess
import wave
from pathlib import Path

import numpy as np
from scipy import signal
from scipy.ndimage import maximum_filter1d

RATE = 44100


# --- Tiempo y ruido -------------------------------------------------------------------------------------------------

def samples(seconds):
    return int(round(seconds * RATE))


def timeline(seconds):
    """Los instantes (en segundos) de un sonido de `seconds` segundos."""
    return np.arange(samples(seconds)) / RATE


def silence(seconds, channels=1):
    n = samples(seconds)
    return np.zeros(n) if channels == 1 else np.zeros((n, channels))


def generator(seed):
    return np.random.default_rng(seed)


def white(seconds, seed):
    return generator(seed).standard_normal(samples(seconds)) * 0.3


def colored(seconds, seed, exponent):
    """Ruido con espectro 1/f^exponent: 1 es rosa, 2 es café (más grave). Normalizado a pico 1."""
    n = samples(seconds)
    spectrum = np.fft.rfft(generator(seed).standard_normal(n))
    freqs = np.fft.rfftfreq(n, 1 / RATE)
    freqs[0] = freqs[1]
    out = np.fft.irfft(spectrum / freqs ** (exponent / 2), n)
    return out / (np.abs(out).max() + 1e-12)


def pink(seconds, seed):
    return colored(seconds, seed, 1.0)


def brown(seconds, seed):
    return colored(seconds, seed, 2.0)


def smooth_random(seconds, seed, rate_hz, low=0.0, high=1.0):
    """Una curva aleatoria suave entre `low` y `high` que cambia unas `rate_hz` veces por segundo."""
    n = samples(seconds)
    points = max(int(seconds * rate_hz) + 3, 4)
    values = generator(seed).uniform(0, 1, points)
    x = np.linspace(0, points - 3, n)
    curve = np.interp(x, np.arange(points), values)
    curve = signal.sosfiltfilt(signal.butter(1, max(rate_hz, 0.05), fs=RATE, output="sos"), curve)
    curve = (curve - curve.min()) / (np.ptp(curve) + 1e-12)
    return low + (high - low) * curve


def periodic_random(seconds, seed, max_hz, low=0.0, high=1.0):
    """Como smooth_random, pero el final empalma con el comienzo: sirve para los sonidos en bucle."""
    t = timeline(seconds)
    rng = generator(seed)
    curve = np.zeros_like(t)
    for k in range(1, max(int(max_hz * seconds), 1) + 1):
        curve += rng.normal() / k * np.sin(2 * np.pi * k * t / seconds + rng.uniform(0, 2 * np.pi))
    curve = (curve - curve.min()) / (np.ptp(curve) + 1e-12)
    return low + (high - low) * curve


# --- Filtros --------------------------------------------------------------------------------------------------------

def lowpass(x, hz, order=2):
    return signal.sosfilt(signal.butter(order, min(hz, RATE / 2 - 100), "low", fs=RATE, output="sos"), x, axis=0)


def highpass(x, hz, order=2):
    return signal.sosfilt(signal.butter(order, hz, "high", fs=RATE, output="sos"), x, axis=0)


def bandpass(x, low, high, order=2):
    return signal.sosfilt(signal.butter(order, [low, min(high, RATE / 2 - 100)], "band", fs=RATE, output="sos"),
                          x, axis=0)


def _biquad(b, a, x):
    return signal.lfilter(np.array(b) / a[0], np.array(a) / a[0], x, axis=0)


def peaking(x, hz, q, gain_db):
    """Ecualizador de campana (RBJ): sube o baja `gain_db` alrededor de `hz`."""
    a_gain = 10 ** (gain_db / 40)
    w = 2 * np.pi * hz / RATE
    alpha = np.sin(w) / (2 * q)
    return _biquad([1 + alpha * a_gain, -2 * np.cos(w), 1 - alpha * a_gain],
                   [1 + alpha / a_gain, -2 * np.cos(w), 1 - alpha / a_gain], x)


def resonance(x, hz, q):
    """Pasabanda resonante (RBJ, ganancia 1 en el pico): una formante o un modo de vibración."""
    w = 2 * np.pi * hz / RATE
    alpha = np.sin(w) / (2 * q)
    return _biquad([alpha, 0, -alpha], [1 + alpha, -2 * np.cos(w), 1 - alpha], x)


def formants(x, bank):
    """Suma de resonancias: `bank` es una lista de (hz, q, ganancia)."""
    return sum(gain * resonance(x, hz, q) for hz, q, gain in bank)


def moving_resonance(x, hz_curve, q, block=256):
    """Una resonancia cuya frecuencia sigue `hz_curve` (un valor por muestra), por bloques con su estado."""
    out = np.zeros_like(x)
    zi = np.zeros(2)
    for start in range(0, len(x), block):
        hz = float(np.mean(hz_curve[start:start + block]))
        w = 2 * np.pi * hz / RATE
        alpha = np.sin(w) / (2 * q)
        a = np.array([1 + alpha, -2 * np.cos(w), 1 - alpha])
        b = np.array([alpha, 0, -alpha])
        out[start:start + block], zi = signal.lfilter(b / a[0], a / a[0], x[start:start + block], zi=zi)
    return out


# --- Envolventes y mezcla -------------------------------------------------------------------------------------------

def decay(seconds, tau):
    return np.exp(-timeline(seconds) / tau)


def attack_decay(seconds, attack, tau):
    t = timeline(seconds)
    return np.minimum(t / max(attack, 1e-4), 1.0) * np.exp(-np.maximum(t - attack, 0) / tau)


def hump(seconds, peak_at=0.3, power=1.5):
    """Sube y baja suave: una sílaba, una ráfaga, un respiro. `peak_at` es la fracción donde llega al máximo."""
    t = timeline(seconds) / max(seconds, 1e-9)
    rise = np.sin(np.pi / 2 * np.clip(t / peak_at, 0, 1))
    fall = np.cos(np.pi / 2 * np.clip((t - peak_at) / (1 - peak_at), 0, 1))
    return (rise * fall) ** power


def fade(x, fade_in=0.0, fade_out=0.0):
    x = x.copy()
    n_in, n_out = samples(fade_in), samples(fade_out)
    if n_in:
        ramp = np.sin(np.linspace(0, np.pi / 2, n_in)) ** 2
        x[:n_in] *= ramp if x.ndim == 1 else ramp[:, None]
    if n_out:
        ramp = np.cos(np.linspace(0, np.pi / 2, n_out)) ** 2
        x[-n_out:] *= ramp if x.ndim == 1 else ramp[:, None]
    return x


def place(buffer, sound, at, gain=1.0):
    """Suma `sound` a `buffer` desde el segundo `at` (lo que se sale, se corta)."""
    start = samples(at)
    if start >= len(buffer):
        return buffer
    end = min(len(buffer), start + len(sound))
    if start < 0:
        sound, start = sound[-start:], 0
        end = min(len(buffer), len(sound))
    buffer[start:end] += gain * sound[:end - start]
    return buffer


def fit(x, seconds):
    """Recorta o rellena con silencio hasta `seconds` segundos."""
    n = samples(seconds)
    if len(x) >= n:
        return x[:n].copy()
    pad = np.zeros((n - len(x),) + x.shape[1:])
    return np.concatenate([x, pad])


def soft_clip(x, drive=1.0):
    return np.tanh(drive * x) / np.tanh(drive)


def follower(x, attack, release):
    """Envolvente de amplitud con ataque y caída en segundos."""
    level = np.abs(x)
    a_att = np.exp(-1 / (attack * RATE))
    a_rel = np.exp(-1 / (release * RATE))
    smooth = signal.lfilter([1 - a_rel], [1, -a_rel], level)
    fast = signal.lfilter([1 - a_att], [1, -a_att], level)
    return np.maximum(smooth, fast)


def compress(x, threshold_db, ratio, attack=0.005, release=0.12, makeup_db=0.0):
    env = follower(x if x.ndim == 1 else x.mean(axis=1), attack, release)
    level_db = 20 * np.log10(env + 1e-9)
    over = np.maximum(level_db - threshold_db, 0)
    gain = 10 ** ((-over * (1 - 1 / ratio) + makeup_db) / 20)
    return x * (gain if x.ndim == 1 else gain[:, None])


def loop_seamless(x, crossfade):
    """Hace que el final de `x` empalme con su comienzo. `x` debe durar `crossfade` segundos más que el bucle: ese
    sobrante se funde con el comienzo, así que al repetirse no hay salto."""
    n = samples(crossfade)
    body = x[:-n].copy()
    fade_in = np.sin(np.linspace(0, np.pi / 2, n))
    fade_out = np.cos(np.linspace(0, np.pi / 2, n))
    if x.ndim > 1:
        fade_in, fade_out = fade_in[:, None], fade_out[:, None]
    body[:n] = body[:n] * fade_in + x[-n:] * fade_out
    return body


# --- Golpes y resonancias -------------------------------------------------------------------------------------------

def modes(seconds, bank, seed=0, jitter=0.0):
    """Lo que suena al golpear algo: modos (hz, tau, amplitud) que decaen. `jitter` varía las frecuencias."""
    t = timeline(seconds)
    rng = generator(seed)
    out = np.zeros_like(t)
    for hz, tau, amp in bank:
        hz *= 1 + rng.uniform(-jitter, jitter)
        out += amp * np.sin(2 * np.pi * hz * t + rng.uniform(0, 2 * np.pi)) * np.exp(-t / tau)
    return out


def strike(seconds, bank, contact, seed=0, jitter=0.03, brightness=0.3):
    """Un golpe: un impulso de `contact` segundos (más largo = más blando) que excita los modos de `bank`."""
    n_contact = max(samples(contact), 2)
    pulse = np.sin(np.linspace(0, np.pi, n_contact)) ** 2
    excitation = np.zeros(samples(seconds))
    excitation[:n_contact] = pulse
    body = signal.fftconvolve(excitation, modes(seconds, bank, seed, jitter))[:len(excitation)]
    body /= np.abs(body).max() + 1e-12
    click = white(seconds, seed + 1) * decay(seconds, contact * 0.8 + 0.0008)
    click = lowpass(click, 1.0 / max(contact, 1e-4) * 6)
    return body + brightness * click / (np.abs(click).max() + 1e-12)


def impulse_train(seconds, times, seed=0, amp_spread=0.3):
    """Un tren de impulsos en `times`, con amplitudes algo distintas."""
    out = np.zeros(samples(seconds))
    rng = generator(seed)
    for when in times:
        index = samples(when)
        if 0 <= index < len(out):
            out[index] += 1 - rng.uniform(0, amp_spread)
    return out


def friction(seconds, rate_curve, seed=0, jitter=0.25):
    """Fricción que se pega y se suelta (un crujido, un rasguño): impulsos cuya frecuencia sigue `rate_curve`."""
    rng = generator(seed)
    times, now = [], 0.0
    while now < seconds:
        rate = float(rate_curve[min(samples(now), len(rate_curve) - 1)])
        now += 1 / max(rate, 1.0) * (1 + rng.uniform(-jitter, jitter))
        times.append(now)
    return impulse_train(seconds, times, seed + 1, 0.6)


def bubble(seconds, hz, tau, rise=0.4):
    """Una burbuja (Minnaert): un tono que sube un poco y se apaga muy rápido."""
    t = timeline(seconds)
    freq = hz * (1 + rise * t / max(seconds, 1e-9))
    return np.sin(2 * np.pi * np.cumsum(freq) / RATE) * np.exp(-t / tau)


# --- Espacios -------------------------------------------------------------------------------------------------------

def room_ir(seconds, t60, seed, damping_hz=4000.0, predelay=0.0, stereo=False):
    """Respuesta de una sala: ruido que decae (t60 = segundos hasta -60 dB), y los agudos se apagan antes."""
    def channel(s):
        t = timeline(seconds)
        low = lowpass(white(seconds, s), damping_hz * 0.35, 1) * np.exp(-6.9 * t / t60)
        high = highpass(white(seconds, s + 7), damping_hz * 0.35, 1) * np.exp(-6.9 * t / (t60 * 0.45))
        ir = lowpass(low + high, damping_hz, 1)
        ir = np.concatenate([np.zeros(samples(predelay)), ir])
        return ir / (np.sqrt(np.sum(ir ** 2)) + 1e-12)
    if stereo:
        return np.stack([channel(seed), channel(seed + 100)], axis=1)
    return channel(seed)


def reverb(x, ir, wet, dry=1.0):
    """Mezcla `x` con su reverberación. El resultado dura lo mismo que `x`: para conservar la cola, alargar `x` con
    pad() antes. Si `x` o `ir` son estéreo, el resultado es estéreo."""
    if x.ndim == 1 and ir.ndim == 1:
        return dry * x + wet * signal.fftconvolve(x, ir)[:len(x)]
    xs = x if x.ndim > 1 else np.stack([x, x], axis=1)
    irs = ir if ir.ndim > 1 else np.stack([ir, ir], axis=1)
    tail = np.stack([signal.fftconvolve(xs[:, c], irs[:, c])[:len(x)] for c in range(2)], axis=1)
    return dry * xs + wet * tail


def pad(x, seconds):
    """Agrega `seconds` de silencio al final, para que quepa la cola de una reverberación."""
    return np.concatenate([x, np.zeros((samples(seconds),) + x.shape[1:])])


def phone(x, seed=0):
    """Lo que graba y manda el celular de un amigo: sin graves ni agudos extremos, algo comprimido y con un poco
    de soplido de micrófono."""
    y = highpass(x, 170, 2)
    y = lowpass(y, 6800, 4)
    y = peaking(y, 2600, 0.9, 2.5)
    y = compress(y, -24, 2.5, 0.004, 0.15)
    y = soft_clip(y / (np.abs(y).max() + 1e-9) * 0.9, 1.4)
    hiss = highpass(white(len(y) / RATE, seed + 999), 2500) * 0.004
    return y + hiss


def radio(x, drive=2.0):
    """Un parlante chico, como el de una radio: solo los medios, con algo de saturación."""
    y = bandpass(x, 380, 3400, 2)
    y = peaking(y, 1500, 1.2, 3)
    return soft_clip(y / (np.abs(y).max() + 1e-9), drive)


def muffle(x, hz=900, room=None):
    """Lo que se oye a través de una pared o del piso: solo los graves, con algo de cuerpo."""
    y = lowpass(x, hz, 4)
    y = peaking(y, 220, 1.0, 4)
    return y if room is None else reverb(y, room, 0.25)


# --- Grabaciones ----------------------------------------------------------------------------------------------------

def load(path, start=None, end=None):
    """Lee una grabación (cualquier formato que entienda ffmpeg) en mono, a 44 100 Hz, entre `start` y `end`."""
    command = ["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"]
    data = np.frombuffer(subprocess.run(command, check=True, capture_output=True).stdout, dtype=np.float32)
    data = data.astype(np.float64)
    if start is not None or end is not None:
        data = data[samples(start or 0):samples(end) if end is not None else None]
    return data


def speed(x, ratio):
    """Más rápido y más agudo (ratio > 1) o más lento y más grave (ratio < 1), como una cinta."""
    from fractions import Fraction
    fraction = Fraction(ratio).limit_denominator(200)
    return signal.resample_poly(x, fraction.denominator, fraction.numerator)


def pitch(x, ratio):
    """Cambia la altura sin cambiar la duración (rubberband de ffmpeg)."""
    raw = x.astype(np.float32).tobytes()
    command = ["ffmpeg", "-v", "error", "-f", "f32le", "-ar", str(RATE), "-ac", "1", "-i", "-",
               "-af", f"rubberband=pitch={ratio}:formant=preserved", "-f", "f32le", "-"]
    out = np.frombuffer(subprocess.run(command, input=raw, check=True, capture_output=True).stdout, dtype=np.float32)
    return fit(out.astype(np.float64), len(x) / RATE)


def tempo(x, ratio):
    """Más rápido (ratio > 1) o más lento sin cambiar la altura (atempo de ffmpeg)."""
    raw = x.astype(np.float32).tobytes()
    command = ["ffmpeg", "-v", "error", "-f", "f32le", "-ar", str(RATE), "-ac", "1", "-i", "-",
               "-af", f"atempo={ratio}", "-f", "f32le", "-"]
    out = np.frombuffer(subprocess.run(command, input=raw, check=True, capture_output=True).stdout, dtype=np.float32)
    return out.astype(np.float64)


# --- Sonoridad y escritura ------------------------------------------------------------------------------------------

def _k_weight(x):
    """El filtro K de la norma ITU-R BS.1770, calculado para 44 100 Hz."""
    def shelf(f0, gain_db, q):
        k = np.tan(np.pi * f0 / RATE)
        vh, vb = 10 ** (gain_db / 20), 10 ** (gain_db / 20) ** 0.4996667741545416
        a0 = 1 + k / q + k * k
        b = [(vh + vb * k / q + k * k) / a0, 2 * (k * k - vh) / a0, (vh - vb * k / q + k * k) / a0]
        a = [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]
        return b, a

    def high(f0, q):
        k = np.tan(np.pi * f0 / RATE)
        a0 = 1 + k / q + k * k
        return [1, -2, 1], [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]

    b, a = shelf(1681.974450955533, 3.999843853973347, 0.7071752369554196)
    y = signal.lfilter(b, a, x, axis=0)
    b, a = high(38.13547087602444, 0.5003270373238773)
    return signal.lfilter(b, a, y, axis=0)


def loudness(x):
    """Sonoridad integrada en LUFS (BS.1770, con las compuertas de -70 LUFS y -10 LU)."""
    y = _k_weight(x)
    power = y ** 2 if y.ndim == 1 else (y ** 2).sum(axis=1)
    block, step = samples(0.4), samples(0.1)
    if len(power) <= block:
        return -0.691 + 10 * np.log10(power.mean() + 1e-12)
    blocks = np.array([power[i:i + block].mean() for i in range(0, len(power) - block + 1, step)])
    lufs = -0.691 + 10 * np.log10(blocks + 1e-12)
    gated = blocks[lufs > -70]
    if len(gated) == 0:
        return -70.0
    relative = -0.691 + 10 * np.log10(gated.mean()) - 10
    gated = blocks[(lufs > -70) & (lufs > relative)]
    return -0.691 + 10 * np.log10(gated.mean() + 1e-12)


def limit(x, ceiling_db=-1.0, release=0.06):
    """Limitador: ningún pico pasa de `ceiling_db`. Baja al instante y se recupera en `release` segundos."""
    ceiling = 10 ** (ceiling_db / 20)
    level = np.abs(x) if x.ndim == 1 else np.abs(x).max(axis=1)
    peak = maximum_filter1d(level, samples(0.003) * 2 + 1)
    gain = np.minimum(1.0, ceiling / (peak + 1e-12))
    gain = np.minimum(gain, 1.0 - follower(1.0 - gain, 0.0005, release))
    return x * (gain if x.ndim == 1 else gain[:, None])


def master(x, lufs, ceiling_db=-1.0):
    """Lleva `x` a la sonoridad `lufs` y limita los picos a `ceiling_db`."""
    x = x - (x.mean(axis=0))
    y = x * 10 ** ((lufs - loudness(x)) / 20)
    for _ in range(3):
        y = limit(y, ceiling_db)
        y = y * 10 ** ((lufs - loudness(y)) / 20) if abs(loudness(y) - lufs) > 0.3 else y
    return limit(y, ceiling_db)


def write(path, x, seed=0):
    """WAV de 16 bits a 44 100 Hz, mono o estéreo, con dither triangular."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    rng = generator(seed + 4242)
    dither = (rng.uniform(-0.5, 0.5, x.shape) + rng.uniform(-0.5, 0.5, x.shape)) / 32768
    data = np.clip(np.round((x + dither) * 32767), -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1 if x.ndim == 1 else x.shape[1])
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data.tobytes())


def read(path):
    """Lee un WAV de 16 bits en flotantes entre -1 y 1."""
    with wave.open(str(path), "rb") as source:
        channels = source.getnchannels()
        data = np.frombuffer(source.readframes(source.getnframes()), dtype="<i2").astype(np.float64) / 32768
    return data if channels == 1 else data.reshape(-1, channels)
