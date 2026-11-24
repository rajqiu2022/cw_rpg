"""Build a short, non-looping victory cue from the player-approved Linxi theme.

This deliberately avoids synthesizing new instruments.  The accepted field theme is
the source of truth until bespoke tracks pass an audible human review gate.
"""

from __future__ import annotations

import audioop
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "game/art/audio/bgm/bgm_linxi_village_v6.wav"
OUTPUT = ROOT / "game/art/audio/bgm/bgm_victory_v4_approved.wav"


def main() -> None:
    start_seconds = 21.0
    duration_seconds = 8.0
    fade_seconds = 0.55

    with wave.open(str(SOURCE), "rb") as src:
        params = src.getparams()
        src.setpos(min(int(start_seconds * params.framerate), params.nframes - 1))
        frames = src.readframes(int(duration_seconds * params.framerate))

    frame_width = params.nchannels * params.sampwidth
    total_frames = len(frames) // frame_width
    fade_frames = max(1, int(fade_seconds * params.framerate))
    chunks: list[bytes] = []
    for index in range(total_frames):
        frame = frames[index * frame_width : (index + 1) * frame_width]
        gain = 1.0
        if index < fade_frames:
            gain = index / fade_frames
        elif index >= total_frames - fade_frames:
            gain = (total_frames - index - 1) / fade_frames
        chunks.append(audioop.mul(frame, params.sampwidth, max(0.0, gain)))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as dst:
        dst.setparams(params)
        dst.writeframes(b"".join(chunks))

    print(f"wrote {OUTPUT.relative_to(ROOT)} ({total_frames / params.framerate:.2f}s)")


if __name__ == "__main__":
    main()
