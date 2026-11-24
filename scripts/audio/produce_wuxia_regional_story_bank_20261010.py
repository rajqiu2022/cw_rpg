"""Twenty authorized regional/story/battle candidates; offline CPU, NEW assets.

Reuse the sealed official-inference/float-WAV/preview kernel unchanged. Record
this runner before RUNNING/FAILED writes. After full pieces, derive staging loops
through the existing numeric selector; loop phrase listening remains pending.
"""
from pathlib import Path
import json
import math
import sys
import numpy as np
import produce_wuxia_stable_personal_continuation as producer
import produce_wuxia_audio_bank_v9 as loop_kernel

ROOT = producer.ROOT
RAW = ROOT / "assets/raw/audio/wuxia_regional_story_bank_20261010"
PROCESSED = ROOT / "assets/processed/audio/wuxia_regional_story_bank_20261010"
PLAN = Path(__file__).with_name("wuxia_regional_story_bank_plan_20261010.json")
SR = 44100


def make_loop(track):
    source = RAW / (track["id"] + "_raw.wav")
    audio = loop_kernel.load(source)
    end_frame = round(track["analysis_end_seconds"] * SR)
    loop, selection = loop_kernel.select_loop(audio[:, :end_frame], track)
    if selection["loop_seconds"] < track["minimum_loop_seconds"]:
        raise ValueError("Loop below fixed minimum")
    pre_rms, pre_peak = loop_kernel.rms(loop), float(np.abs(loop).max())
    if not np.isfinite(loop).all() or pre_rms <= 1e-5:
        raise ValueError("Invalid loop")
    rms_gain, peak_gain = 10 ** (-22 / 20) / pre_rms, 10 ** (-3 / 20) / pre_peak
    gain = min(rms_gain, peak_gain)
    processed = loop * gain
    stem = track["id"]
    wav = PROCESSED / (stem + "_loop.wav")
    mp3 = wav.with_suffix(".mp3")
    seam_wav = PROCESSED / (stem + "_two_cycle_seam10.wav")
    seam_mp3 = seam_wav.with_suffix(".mp3")
    if any(p.exists() for p in (wav, mp3, seam_wav, seam_mp3)):
        raise ValueError("Existing loop preserved")
    loop_kernel.save_pcm(wav, processed)
    loop_kernel.save_mp3(mp3, processed)
    seam = np.concatenate([processed[:, -5 * SR:], processed[:, :5 * SR]], axis=1)
    loop_kernel.save_pcm(seam_wav, seam)
    loop_kernel.save_mp3(seam_mp3, seam)
    jump = np.abs(processed[:, 0] - processed[:, -1])
    q999 = np.quantile(np.abs(np.diff(processed, axis=1)), .999, axis=1)
    return {"status": "LOOP_LISTENING_PENDING", "source": producer.record(source),
        "track": track, "sample_rate": SR, "channels": 2,
        "analysis_source_start_frame": 0, "analysis_source_end_frame_exclusive": end_frame,
        "loop": selection,
        "processing": {"linear_gain": gain, "gain_db": 20 * math.log10(gain),
            "target_rms_dbfs": -22, "peak_cap_dbfs": -3, "peak_cap_limited": peak_gain < rms_gain,
            "pre_gain_loop_rms": pre_rms, "pre_gain_loop_peak": pre_peak,
            "actual_rms_dbfs": 20 * math.log10(loop_kernel.rms(processed)),
            "actual_peak": float(np.abs(processed).max()), "quantization": "trunc_int16",
            "pcm_scale": 32767, "edge_silence_fade": False},
        "boundary": {"jump_by_channel": jump.tolist(), "internal_step_q999_by_channel": q999.tolist(),
            "jump_below_internal_q999": bool(np.all(jump <= q999)),
            "preserved_original_adjacent_source_pair": True,
            "note": "Numeric feature matching and boundary continuity are not musical phrase approval."},
        "seam_audition": {"seconds": 10, "frames": 10 * SR, "join_frame": 5 * SR,
            "construction": "last5s(cycle1)+first5s(cycle2); no edge fade"},
        "outputs": [producer.record(p) for p in (wav, mp3, seam_wav, seam_mp3)],
        "model_invocation_for_processing": "NONE", "formal_runtime_adopted": False,
        "runtime_loop_flag": "No embedded loop flag; full-file runtime loop mode requires later game integration."}


def main():
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    if len(plan["tracks"]) != 20 or len({t["id"] for t in plan["tracks"]}) != 20:
        raise SystemExit("Fixed twenty-theme plan mismatch")
    if any(t["seconds"] not in (72, 96) or t["analysis_end_seconds"] >= t["seconds"] for t in plan["tracks"]):
        raise SystemExit("Duration/analysis plan mismatch")
    producer.PLAN, producer.RAW, producer.PROCESSED = PLAN, RAW, PROCESSED
    original_write_json = producer.write_json
    runner_record = producer.record(Path(__file__))
    completed = set()

    def annotate_write_json(path, data):
        data["continuation_runner"] = runner_record
        original_write_json(path, data)
        if data.get("processing") and data.get("generation_status") == "COMPLETE" and data["id"] not in completed:
            completed.add(data["id"])
            print("BANK_FULL_READY", len(completed), "/20", data["id"], flush=True)

    producer.write_json = annotate_write_json
    # Sealed kernel's --track all accepts the entire NEW fixed plan transparently.
    # No generation flags, commercial gate, model change, retry or reference audio.
    sys.argv = [sys.argv[0], "--track", "all"]
    producer.main()
    loops = []
    for index, track in enumerate(plan["tracks"], 1):
        try:
            result = make_loop(track)
        except ValueError as error:
            # Keep the complete piece and actual failed selector evidence; do not
            # regenerate music or silently reselect by changing parameters.
            result = {"status": "LOOP_PROCESSING_FAILED", "track": track,
                      "source": producer.record(RAW / (track["id"] + "_raw.wav")),
                      "error": str(error), "automatic_retry": False}
        result["continuation_runner"] = runner_record
        result["selection_io_kernel"] = producer.record(Path(loop_kernel.__file__))
        producer.write_json(PROCESSED / (track["id"] + ".loop.processing.json"), result)
        loops.append(result)
        print("BANK_LOOP_READY", index, "/20", track["id"], result["status"], flush=True)
    manifest_path = PROCESSED / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest.update({"bank_scope": "20 regional/story/battle themes; all new listening pending",
                     "loops": loops, "game_integration": "NONE", "no_automatic_model_retry": True})
    producer.write_json(manifest_path, manifest)


if __name__ == "__main__":
    main()
