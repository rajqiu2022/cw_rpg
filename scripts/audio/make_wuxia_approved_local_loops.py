"""NEW staging loops from approved full outputs; no inference or engine call.

Read-only reuse of stable feature-selection/audio I/O helpers. Never invokes
the old bank's main, process, commercial gate or model-loading functions.
"""
from pathlib import Path
import json
import math
import numpy as np
import produce_wuxia_audio_bank_v9 as kernel

ROOT = kernel.ROOT
SR = kernel.SR
DEST = ROOT / "assets/processed/audio/wuxia_approved_local_loops_20261009"
PLAN = Path(__file__).with_name("wuxia_approved_local_loops_plan_20261009.json")


def main():
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    if len(plan["tracks"]) != 3 or plan["model_invocation"] != "NONE":
        raise ValueError("Fixed three approved-output plan mismatch")
    if DEST.exists() and any(DEST.glob("*.processing.json")):
        raise SystemExit("Preserving existing loop attempt")
    DEST.mkdir(parents=True, exist_ok=True)
    results = []
    for track in plan["tracks"]:
        base = DEST / track["id"]
        outputs = [base.with_name(base.name + suffix) for suffix in
                   ("_loop.wav", "_loop.mp3", "_two_cycle_seam10.wav", "_two_cycle_seam10.mp3")]
        if any(p.exists() for p in outputs):
            raise SystemExit("Existing staged output preserved: " + track["id"])
        source = ROOT / track["source"]
        if kernel.sha(source) != track["source_sha256"]:
            raise ValueError("Approved source SHA mismatch")
        audio = kernel.load(source)
        if not np.isfinite(audio).all() or kernel.rms(audio) <= 1e-5:
            raise ValueError("Invalid approved source")
        analysis_end = round(track["analysis_end_seconds"] * SR)
        if analysis_end > audio.shape[1]:
            raise ValueError("Analysis prefix exceeds source")
        loop, selection = kernel.select_loop(audio[:, :analysis_end], track)
        if selection["loop_seconds"] < track["minimum_loop_seconds"]:
            raise ValueError("Selected loop is too short")
        raw_rms, raw_peak = kernel.rms(loop), float(np.abs(loop).max())
        rms_gain, peak_gain = 10 ** (-22 / 20) / raw_rms, 10 ** (-3 / 20) / raw_peak
        gain = min(rms_gain, peak_gain)
        loop = loop * gain
        kernel.save_pcm(outputs[0], loop)
        kernel.save_mp3(outputs[1], loop)
        seam = np.concatenate([loop[:, -5 * SR:], loop[:, :5 * SR]], axis=1)
        kernel.save_pcm(outputs[2], seam)
        kernel.save_mp3(outputs[3], seam)
        jumps = np.abs(loop[:, 0] - loop[:, -1])
        q999 = np.quantile(np.abs(np.diff(loop, axis=1)), .999, axis=1)
        result = {
            "status": "LOOP_LISTENING_PENDING", "purpose": plan["purpose"],
            "source": kernel.record(source), "source_full_seconds": audio.shape[1] / SR,
            "source_full_listening": "USER_APPROVED", "track": track,
            "sample_rate": SR, "channels": 2, "analysis_source_start_frame": 0,
            "analysis_source_end_frame_exclusive": analysis_end,
            "loop": selection,
            "processing": {"linear_gain": gain, "gain_db": 20 * math.log10(gain),
                "pre_gain_loop_rms": raw_rms, "pre_gain_loop_peak": raw_peak,
                "target_rms_dbfs": -22, "peak_cap_dbfs": -3, "peak_cap_limited": peak_gain < rms_gain,
                "actual_rms_dbfs": 20 * math.log10(kernel.rms(loop)), "actual_peak": float(np.abs(loop).max()),
                "quantization": "trunc_int16", "pcm_scale": 32767, "edge_silence_fade": False},
            "boundary": {"jump_by_channel": jumps.tolist(), "internal_step_q999_by_channel": q999.tolist(),
                "jump_below_internal_q999": bool(np.all(jumps <= q999)),
                "preserved_original_adjacent_source_pair": True,
                "note": "Feature matching and numeric boundary checks do not approve musical phrasing or an inaudible seam."},
            "seam_audition": {"seconds": 10, "frames": 10 * SR, "join_frame": 5 * SR,
                "construction": "last5s(cycle1)+first5s(cycle2); direct concatenate, no edge fade"},
            "outputs": [kernel.record(p) for p in outputs], "model_invocation": "NONE",
            "formal_runtime_adopted": False, "game_integration": "NONE",
            "runtime_loop_flag": "Not embedded in PCM WAV; game integration requires explicit loop mode later."
        }
        metadata = DEST / (track["id"] + ".processing.json")
        metadata.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        results.append(result)
        print("STAGED_LOOP_READY", track["id"], selection["loop_seconds"], selection["selected"], flush=True)
    manifest = {"status": "LOOP_LISTENING_PENDING", "purpose": plan["purpose"],
        "model_invocation": "NONE", "game_integration": "NONE", "plan": kernel.record(PLAN),
        "script": kernel.record(Path(__file__)), "selection_io_kernel": kernel.record(Path(kernel.__file__)),
        "tracks": results}
    (DEST / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
