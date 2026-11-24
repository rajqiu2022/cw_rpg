"""Original wuxia cadence, physically modelled plucked strings and bronze percussion."""
from pathlib import Path
import wave
import numpy as np

rate = 48000
duration = 4.36
rng = np.random.default_rng(217)
mix = np.zeros((round(rate * duration), 2))


def t_for(seconds):
    return np.arange(round(rate * seconds)) / rate


def place(when, signal, volume, pan=0.0):
    start = round(when * rate)
    signal = signal[:len(mix) - start]
    mix[start:start+len(signal)] += signal[:, None] * volume * np.sqrt([(1-pan)/2, (1+pan)/2])


def string(note, seconds, bite=0.22):
    freq = 440 * 2 ** ((note - 69) / 12)
    period = round(rate / freq - 0.5)
    excitation = rng.uniform(-1, 1, period)
    excitation -= np.roll(excitation, round(period*bite))
    waveguide = np.zeros(round(rate * seconds))
    waveguide[:period] = excitation * .56
    for i in range(period, len(waveguide)):
        j = i - period
        waveguide[i] = .995 * (.53 * waveguide[j] + .47 * waveguide[j-1])
    t = t_for(seconds)
    # A short resonant box and a quieter body tone warm the transient.
    box = np.sin(2*np.pi*freq*t) * np.exp(-4.7*t)
    return (.74 * waveguide + .37 * box + .12 * np.sin(4*np.pi*freq*t) * np.exp(-8*t)) * np.minimum(t/.007, 1) * np.minimum((seconds-t)/.09,1)


def skin(seconds=.52):
    t = t_for(seconds)
    p = 2*np.pi*(51*t + 1.42*(1-np.exp(-27*t)))
    transient = .22*rng.normal(size=len(t))*np.exp(-130*t)
    return np.minimum(t/.005,1)*(np.sin(p)*np.exp(-10*t)+.32*np.sin(p*1.61)*np.exp(-24*t)+transient)


def bronze(seconds):
    t = t_for(seconds)
    sound = np.zeros_like(t)
    for n, f in enumerate([167,263,347,490,612,774,1154,1498,1841]):
        bend = .17*(1-np.exp(-29*t))
        sound += np.sin(2*np.pi*f*t + (n+1)*bend)*np.exp(-(1.5+.72*n)*t)/(n+1)**.84
    return sound*np.minimum(t/.016,1)*np.minimum((seconds-t)/.20,1)


# D–F–G–A–C: a compact answer in two phrases with an open fifth cadence.
for at, note, length in [(0.07,62,.40),(.23,65,.29),(.37,69,.31),(.51,74,.61),(.89,72,.27),
                         (1.03,69,.27),(1.17,67,.38),(1.40,65,.37),(1.69,67,.27),
                         (1.83,69,.28),(1.97,72,.34),(2.22,74,1.16)]:
    place(at,string(note,length),.52,-.20)
for at,note,length in [(.0,38,.72),(.51,45,.62),(1.18,43,.52),(1.72,45,.55),(2.22,38,1.43),(2.26,45,1.21),(2.30,50,1.10)]:
    place(at,string(note,length,.31),.35,.18)
for at,gain in [(0,.65),(.37,.26),(.51,.58),(1.18,.40),(1.96,.23),(2.09,.32),(2.22,.56)]:
    place(at,skin(),gain)
place(.51,bronze(1.25),.16,.25)
place(2.22,bronze(2.08),.24,.14)
dry=mix.copy()
for delay,gain in [(.031,.10),(.057,.10),(.108,.063),(.173,.045)]:
    n=round(rate*delay)
    mix[n:]+=gain*dry[:-n,::-1]
mix *= np.minimum(t_for(duration)[::-1]/.31,1)[:,None]
mix *= .82/max(np.abs(mix).max(),.001)
dest = Path(__file__).resolve().parents[2]/'art/audio/bgm/bgm_victory_wuxia_cadence_20261109.wav'
with wave.open(str(dest),'wb') as stream:
    stream.setparams((2,2,rate,0,'NONE','not compressed'))
    stream.writeframes((mix*32767).astype('<i2').tobytes())
