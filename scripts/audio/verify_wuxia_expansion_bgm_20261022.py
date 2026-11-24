"""Bounded new-bank QA reusing sealed regional PCM/loop/decoder assertions.
No model, network, Godot, import, production write or old-city guard.
"""
import os
os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
import argparse,json
from pathlib import Path
import numpy as np
from scipy.io import wavfile
from audit_wuxia_expansion_20261022 import ROOT,OUT,record,sha,save
from verify_wuxia_audio_loops import changes,wav_observation
from verify_wuxia_audio_trial import inspect_wav,inspect_mp3
from verify_wuxia_regional_story_bank import processed_internal_energy
RAW=ROOT/"assets/raw/audio/wuxia_expansion_20261022"
PROCESSED=ROOT/"assets/processed/audio/wuxia_expansion_20261022"

def protection():
    before=json.loads((OUT/"before.json").read_text(encoding="utf-8"))
    groups={k:changes(before[k]) for k in ("audio_files","audio_sources","skill_dialog_enemy_equipment_data","player_files")}
    extra=json.loads((OUT/"before_nested_dialogs_supplement.json").read_text(encoding="utf-8"))
    groups["nested63_dialogue_supplement"]=changes(extra["files"])
    return {"deltas":groups,"unchanged":not any(groups.values()),"player_path_count":15,"no_rollback_or_auto_rebaseline":True}

def verify(expected_count=20, report_name="bgm_original20.json"):
    before = protection()
    manifest_path = PROCESSED / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    files = {}
    def check(row):
        path = Path(row["path"])
        if not path.is_absolute():
            path = ROOT / path
        key = str(path.resolve())
        if key not in files:
            files[key] = record(path)
        assert files[key]["sha256"] == row["sha256"] and files[key]["bytes"] == row["size"], key
        return path
    plan = json.loads(check(manifest["plan"]).read_text(encoding="utf-8"))
    assert len(plan["tracks"]) == expected_count and len({t["id"] for t in plan["tracks"]}) == expected_count and len({t["seed"] for t in plan["tracks"]}) == expected_count
    assert plan["steps"] == 8 and plan["threads"] == 6 and plan["purpose"] == "PERSONAL_NONCOMMERCIAL_EVALUATION"
    assert manifest["game_integration"] == "NONE"
    check(manifest["production_script"])
    check(manifest["continuation_runner"])
    planned = {t["id"]: t for t in plan["tracks"]}
    assert len(manifest["tracks"]) == expected_count and {t["id"] for t in manifest["tracks"]} == set(planned)
    loops = {t["track"]["id"]: t for t in manifest["loops"]}
    assert len(loops) == expected_count and set(loops) == set(planned)
    results = []
    for number, meta in enumerate(manifest["tracks"], 1):
        result = {"id": meta["id"], "technical_pass": False, "audible_style_approval": False, "audible_loop_approval": False}
        try:
            target = planned[meta["id"]]
            assert all(meta[k] == target[k] for k in ("prompt", "seed", "seconds"))
            assert meta["generation_status"] == "COMPLETE" and meta["inference_exit_code"] == 0
            assert meta["model_revision"] == plan["model_revision"] and meta["runtime_revision"] == plan["runtime_revision"]
            assert meta["steps"] == 8 and meta["threads"] == 6
            command = meta["command"]
            for flag, value in (("--dit", "sm-music"), ("--decoder", "same-s"), ("--dit-precision", "fp32"), ("--decoder-precision", "w8a8"), ("--prompt", target["prompt"]), ("--seed", str(target["seed"])), ("--seconds", str(target["seconds"])), ("--steps", "8"), ("--threads", "6")):
                assert command[command.index(flag) + 1] == value
            for key in ("production_script", "frozen_float_wrapper", "frozen_io_helper", "continuation_runner", "plan_file", "runtime_preparation", "inference_log"):
                check(meta[key])
            if "preserved_original_bank_manifest" in meta:
                check(meta["preserved_original_bank_manifest"])
            assert len(meta["model_files"]) == 3
            for row in meta["model_files"] + meta["licenses"] + meta["raw_outputs"]:
                check(row)
            meta_path = RAW / (meta["id"] + ".meta.json")
            assert json.loads(meta_path.read_text(encoding="utf-8")) == meta
            processing = meta["processing"]
            raw_path = check(processing["source"])
            assert raw_path.resolve().is_relative_to(RAW.resolve())
            rate, raw = wavfile.read(raw_path)
            assert raw.dtype == np.float32 and rate == 44100 and raw.shape == (target["seconds"] * rate, 2)
            assert np.isfinite(raw).all() and np.any(raw)
            planar = np.ascontiguousarray(raw.T)
            rms = float(np.sqrt(np.mean(planar.astype(np.float64) ** 2)))
            peak = float(np.abs(raw).max())
            gain = min(10 ** (-22 / 20) / rms, 10 ** (-3 / 20) / peak)
            assert rms == processing["source_rms"] and peak == processing["source_peak"] and gain == processing["linear_gain"]
            assert processing["pcm_scale"] == 32767 and processing["quantization"] == "trunc_int16" and processing["edge_fade_frames"] == 662
            audition = planar * gain
            audition[:, :662] *= np.linspace(0, 1, 662, dtype=np.float32)
            audition[:, -662:] *= np.linspace(1, 0, 662, dtype=np.float32)
            preview = audition[:, :30 * rate].copy()
            assert processing["preview_frames"] == 30 * rate and processing["preview_end_fade_frames"] == 2205
            preview[:, -2205:] *= np.linspace(1, 0, 2205, dtype=np.float32)
            wavs, mp3s = [], []
            for output in processing["outputs"]:
                path = check(output)
                assert path.resolve().is_relative_to(PROCESSED.resolve())
                expected = preview if "first30s" in path.name else audition
                if path.suffix == ".wav":
                    out_rate, pcm = wavfile.read(path)
                    assert out_rate == rate and pcm.dtype == np.int16 and np.array_equal(pcm, (expected.T * 32767).astype(np.int16))
                    observation = inspect_wav(path)
                    assert observation["finite_nonzero_pass"] and observation["integer_full_scale_sample_count"] == 0 and max(observation["peak_per_channel"]) < 10 ** (-3 / 20)
                    wavs.append(observation)
                else:
                    observation = inspect_mp3(path)
                    assert observation["technical_decode_pass"] and observation["sample_rate_hz"] == rate and observation["channels"] == 2 and observation["decoded_frames"] == expected.shape[1]
                    mp3s.append(observation)
            assert len(wavs) == len(mp3s) == 2
            decoder_path = raw_path.with_suffix(".decoder.json")
            decoder = json.loads(decoder_path.read_text(encoding="utf-8"))
            assert decoder["frames"] == len(raw) and decoder["sample_rate"] == rate and decoder["raw_peak"] == peak and decoder["raw_rms"] == rms
            assert decoder["finite"] is True and decoder["export_clipping"] is False and decoder["samples_above_unity"] == int(np.count_nonzero(np.abs(raw) > 1))
            signal = inspect_wav(raw_path)
            quiet = {"low_energy_observations": "RAW_NOT_REMEASURED; processed_full_internal_energy is actual40ms body observation"}
            audition_path = ROOT / next(row["path"] for row in processing["outputs"] if row["path"].endswith("_audition.wav"))
            processed_energy = processed_internal_energy(audition_path, target["analysis_end_seconds"])
            result.update(metadata=record(meta_path), raw=signal, decoder=record(decoder_path), raw_low_energy_observations=quiet["low_energy_observations"], rms_window_seconds=.05, rms_hop_seconds=.01, processed_full_internal_energy=processed_energy, low_energy_is_observation_not_listening_approval=True, full_and_preview_pcm_exact=True, full_and_preview_wav=wavs, full_and_preview_mp3=mp3s)
            loop = loops[meta["id"]]
            assert loop["track"] == target
            assert json.loads((PROCESSED / (meta["id"] + ".loop.processing.json")).read_text(encoding="utf-8")) == loop
            check(loop["continuation_runner"])
            check(loop["selection_io_kernel"])
            if "loop_processing_kernel" in loop:
                check(loop["loop_processing_kernel"])
            if loop["status"] == "LOOP_PROCESSING_FAILED":
                result["loop_actual_failure_preserved"] = loop
                raise ValueError("Actual loop processing failed: " + loop["error"])
            assert check(loop["source"]).resolve() == raw_path.resolve()
            selected = loop["loop"]["selected"]
            start, end, overlap = [selected[k] for k in ("start_frame", "end_frame", "crossfade_frames")]
            assert 0 <= start < start + overlap < end - overlap < end <= loop["analysis_source_end_frame_exclusive"] == round(target["analysis_end_seconds"] * rate)
            assert overlap == round(target["crossfade_seconds"] * rate)
            weight = np.linspace(0, 1, overlap, dtype=np.float32)[:, None]
            joined = np.concatenate([raw[start + overlap:end - overlap], raw[end - overlap:end] * (1 - weight) + raw[start:start + overlap] * weight])
            loop_rms = float(np.sqrt(np.mean(np.ascontiguousarray(joined.T).astype(np.float64) ** 2)))
            loop_peak = float(np.abs(joined).max())
            loop_gain = min(10 ** (-22 / 20) / loop_rms, 10 ** (-3 / 20) / loop_peak)
            lp = loop["processing"]
            assert lp["linear_gain"] == loop_gain and lp["pre_gain_loop_rms"] == loop_rms and lp["pre_gain_loop_peak"] == loop_peak
            assert lp["quantization"] == "trunc_int16" and lp["pcm_scale"] == 32767 and lp["edge_silence_fade"] is False
            assert len(joined) == loop["loop"]["loop_frames"] and len(joined) / rate >= target["minimum_loop_seconds"]
            paths = [check(row) for row in loop["outputs"]]
            loop_path = next(p for p in paths if p.name.endswith("_loop.wav"))
            seam_path = next(p for p in paths if p.name.endswith("_seam10.wav"))
            lr, pcm = wavfile.read(loop_path)
            sr, seam = wavfile.read(seam_path)
            assert lr == sr == rate and pcm.dtype == seam.dtype == np.int16
            assert np.array_equal(pcm, (joined * loop_gain * 32767).astype(np.int16))
            assert np.array_equal(seam, np.concatenate([pcm[-5 * rate:], pcm[:5 * rate]]))
            assert np.array_equal(joined[0] - joined[-1], raw[start + overlap] - raw[start + overlap - 1])
            loop_wavs = [wav_observation(loop_path), wav_observation(seam_path)]
            assert all(w["finite_nonzero"] and w["integer_full_scale_samples"] == 0 and max(w["peak_per_channel"]) < 10 ** (-3 / 20) for w in loop_wavs)
            loop_mp3 = [inspect_mp3(p) for p in paths if p.suffix == ".mp3"]
            assert len(loop_mp3) == 2 and all(d["technical_decode_pass"] and d["sample_rate_hz"] == rate and d["channels"] == 2 and d["decoded_frames"] == (10 * rate if "seam10" in d["path"] else len(joined)) for d in loop_mp3)
            result.update(loop_selection=selected, loop_pcm_exact=True, seam_last5_plus_first5_pcm_exact=True, original_adjacent_source_boundary_preserved=True, loop_wav=loop_wavs, loop_mp3=loop_mp3, technical_pass=True)
        except Exception as error:
            result["error"] = repr(error)
        results.append(result)
        print("QA_TRACK", number, "/" + str(expected_count), meta["id"], "PASS" if result["technical_pass"] else result.get("error"), flush=True)
    after=protection()
    result={"scope":"NEW_BGM_EXPANSION_ONLY_READONLY_OFFLINE","technical_pass":all(x["technical_pass"] for x in results),"protection_unchanged":before["unchanged"] and after["unchanged"],"manifest":record(manifest_path),"verifier_source":record(Path(__file__)),"checked_files":list(files.values()),"tracks":results,"protection_before":before,"protection_after":after,"model_invocations_by_qa":0,"engine_by_qa":0,"game_writes_by_qa":0,"style_loop_listening":"PENDING","no_formal_adoption":True}
    save(report_name,result)
    print(json.dumps({"technical_pass":result["technical_pass"],"protection_unchanged":result["protection_unchanged"],"report":str(OUT/report_name),"sha256":sha(OUT/report_name)}),flush=True)
    return result

if __name__=="__main__":
    ap=argparse.ArgumentParser();ap.add_argument("--alt",action="store_true");a=ap.parse_args()
    if a.alt:
        RAW=ROOT/"assets/raw/audio/wuxia_expansion_investigation_alt_20261022"
        PROCESSED=ROOT/"assets/processed/audio/wuxia_expansion_investigation_alt_20261022"
    result=verify(1 if a.alt else 20,"bgm_investigation_alt.json" if a.alt else "bgm_original20.json")
    raise SystemExit(0 if result["technical_pass"] else 1)
