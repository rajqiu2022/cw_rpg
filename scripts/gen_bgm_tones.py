"""
gen_bgm_tones.py — 生成简单氛围音调作为场景BGM占位

用法: python scripts/gen_bgm_tones.py

输出: game/art/audio/bgm/ (calm/danger/sad/happy/victory).wav
时长: 30秒循环，正弦波+谐波合成
"""

import struct
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "game" / "art" / "audio" / "bgm"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SAMPLE_RATE = 44100
DURATION = 30  # seconds

# 音阶频率 (中国传统五声音阶: 宫商角徵羽)
PENTATONIC = [261.63, 293.66, 329.63, 392.00, 440.00]  # C D E G A
PENTATONIC_LOW = [f / 2 for f in PENTATONIC]

def sine(freq: float, t: float) -> float:
    return math.sin(2 * math.pi * freq * t)

def saw(freq: float, t: float) -> float:
    return 2 * ((freq * t) % 1.0) - 1.0

def tri(freq: float, t: float) -> float:
    return 2 * abs(2 * ((freq * t + 0.25) % 1.0) - 1.0) - 1.0

def mix(*waves, weights=None):
    if weights is None:
        weights = [1.0 / len(waves)] * len(waves)
    return sum(w * s for w, s in zip(weights, waves))

def render_mood(name: str, freq_func, amp_envelope):
    """生成 WAV 文件"""
    samples = []
    for i in range(SAMPLE_RATE * DURATION):
        t = i / SAMPLE_RATE
        samples.append(freq_func(t) * amp_envelope(t))
    
    max_val = max(abs(s) for s in samples)
    if max_val > 0:
        samples = [s / max_val * 0.7 for s in samples]
    
    path = OUT_DIR / f"bgm_{name}.wav"
    with open(path, "wb") as f:
        data_size = len(samples) * 2
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + data_size))
        f.write(b"WAVE")
        f.write(b"fmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, 1, SAMPLE_RATE, SAMPLE_RATE * 2, 2, 16))
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        for s in samples:
            f.write(struct.pack("<h", int(max(-32768, min(32767, s * 32767)))))
    print(f"  {name}: {path} ({DURATION}s)")


# -- 平淡/日常 (竹尾村、林西村街道) --
def calm_bgm(t: float) -> float:
    return mix(
        sine(PENTATONIC_LOW[0], t) * 0.6,
        sine(PENTATONIC[0], t) * 0.3,
        sine(PENTATONIC_LOW[2], t + 0.5) * 0.1,
    )

# -- 欢喜/热闹 (集市、酒馆) --
def happy_bgm(t: float) -> float:
    return mix(
        tri(PENTATONIC[2], t) * 0.5,
        sine(PENTATONIC[1], t) * 0.3,
        tri(PENTATONIC[0], t * 1.01) * 0.2,
    )

# -- 危险/紧张 (密林、战斗前) --
def danger_bgm(t: float) -> float:
    # 低频振荡 + 不协和
    return mix(
        saw(55.0, t) * 0.4,
        sine(110.0, t) * 0.3,
        sine(165.0, t * 0.97) * 0.3,
    )

# -- 悲伤/难过 (战败、师门离别) --
def sad_bgm(t: float) -> float:
    return mix(
        sine(PENTATONIC_LOW[0], t) * 0.5,
        sine(PENTATONIC_LOW[2], t + 1.3) * 0.3,
        sine(PENTATONIC_LOW[0] * 0.75, t + 2.7) * 0.2,
    )

# -- 胜利 (Boss战后) --
def victory_bgm(t: float) -> float:
    return mix(
        sine(PENTATONIC[3], t) * 0.4,
        sine(PENTATONIC[2], t * 1.005) * 0.3,
        sine(PENTATONIC[0] * 2, t * 1.002) * 0.3,
    )


if __name__ == "__main__":
    print("Generating BGM tones...")
    env = lambda t: min(1.0, t * 3) * max(0.0, 1.0 - t / DURATION)
    render_mood("calm", calm_bgm, env)
    render_mood("happy", happy_bgm, env)
    render_mood("danger", danger_bgm, env)
    render_mood("sad", sad_bgm, env)
    render_mood("victory", victory_bgm, env)
    print("Done.")
