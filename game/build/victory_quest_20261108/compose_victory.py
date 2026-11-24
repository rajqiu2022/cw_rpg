"""Render an original short wuxia fanfare as a 48 kHz stereo WAV."""
from pathlib import Path
import wave
import numpy as np

RATE = 48000
DURATION = 3.72
mix = np.zeros((round(RATE * DURATION), 2))
rng = np.random.default_rng(3108)


def add(start, sound, pan, amplitude):
    offset = round(start * RATE)
    sound = sound[:len(mix) - offset]
    balance = np.sqrt([(1 - pan) / 2, (1 + pan) / 2])
    mix[offset:offset + len(sound)] += amplitude * sound[:, None] * balance


def pluck(note, duration, brightness):
    t = np.arange(round(duration * RATE)) / RATE
    frequency = 440 * 2 ** ((note - 69) / 12)
    attack = 1 - np.exp(-1100 * t)
    tone = np.zeros_like(t)
    for partial in range(1, 12):
        phase = 2 * np.pi * frequency * partial * (1 + .00014 * partial ** 2) * t
        decay = np.exp(-(3.0 + partial * (1.8 - brightness)) * t)
        tone += np.sin(phase) * decay * np.sin(.74 * partial) / partial ** 1.15
    return attack * tone * np.minimum((duration - t) / .12, 1)


def flute(note, duration):
    t = np.arange(round(duration * RATE)) / RATE
    f = 440 * 2 ** ((note - 69) / 12)
    phase = 2 * np.pi * f * t - 1.1 * (1 - np.exp(-40 * t)) + .25 * np.sin(2 * np.pi * 5.6 * t) * (1 - np.exp(-3 * t))
    breath = np.convolve(rng.standard_normal(len(t)), np.array([.12, .25, .26, .25, .12]), mode="same")
    env = np.minimum(t / .045, 1) * np.minimum((duration - t) / .14, 1) * np.exp(-1.1 * t)
    return env * (np.sin(phase) + .29 * np.sin(2 * phase) + .11 * np.sin(3 * phase) + .05 * breath)


def drum():
    t = np.arange(round(.55 * RATE)) / RATE
    phase = 2 * np.pi * (66 * t + 1.65 * (1 - np.exp(-35 * t)))
    rim = rng.standard_normal(len(t)) * np.exp(-85 * t) * .14
    return (1 - np.exp(-1200 * t)) * (.82 * np.sin(phase) * np.exp(-12 * t) + .18 * np.sin(2.27 * phase) * np.exp(-28 * t) + rim)


# D-major pentatonic lift on the raised fist, an answering phrase and a final tonic.
for when, note, length in [(0.00, 62, .19), (.15, 69, .19), (.30, 74, .52), (.76, 76, .26),
                           (.98, 78, .40), (1.34, 76, .21), (1.53, 71, .24), (1.76, 69, .26), (2.04, 74, .97)]:
    add(when, pluck(note, length + .29, .83), -.24, .33)
    if when >= .30:
        add(when + .014, flute(note, length), .15, .20)
for when, note in [(.00, 38), (.30, 50), (.76, 45), (1.53, 47), (2.04, 38), (2.10, 45), (2.16, 50)]:
    add(when, pluck(note, 1.08, .1), .28, .27)
for when, strength in [(0, .56), (.30, .41), (.76, .20), (1.53, .21), (2.04, .30)]:
    add(when, drum(), .02, strength)

dry = mix.copy()
for delay, strength in [(0.039, .10), (.064, .085), (.107, .058), (.173, .04), (.252, .025)]:
    samples = round(RATE * delay)
    mix[samples:] += dry[:-samples, ::-1] * strength
mix *= np.minimum((np.arange(len(mix))[::-1] / RATE / .25), 1)[:, None]
mix *= .76 / np.abs(mix).max()
target = Path(__file__).resolve().parents[2] / 'art/audio/bgm/bgm_victory_salute_20261108.wav'
with wave.open(str(target), "wb") as out:
    out.setparams((2, 2, RATE, 0, 'NONE', 'not compressed'))
    out.writeframes((mix * 32767).astype('<i2').tobytes())

