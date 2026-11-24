"""One final autonomous composition attempt: long phrases and sampled legato.

New score, stable recorded single-note bodies, 120 ms transitions, gentle real
zither tremolo support and a small transparent room return. No model inference.
The rejected v2 score/audio/code and all source files remain untouched.
"""
from pathlib import Path
import argparse
import importlib.util
import json
import math
import numpy as np
from scipy import signal

ROOT=Path(__file__).resolve().parents[2]
RAW=ROOT/"assets/raw/audio/wuxia_original_continuous_v3_20261009"
OUT=ROOT/"assets/processed/audio/wuxia_original_continuous_v3_20261009"
SCORE=Path(__file__).with_name("wuxia_original_continuous_v3_score_20261009.json")
KERNEL=Path(__file__).with_name("compose_wuxia_original_trial.py")
spec=importlib.util.spec_from_file_location("frozen_sample_io",KERNEL)
io=importlib.util.module_from_spec(spec);spec.loader.exec_module(io)
SR=44100
BODY_START,BODY_END=35280,145530
BODY_CENTERS=[67.06137445,68.05943525,69.04663982,70.04588857,71.01330346,72.01486250,73.01783588,74.04429710,75.03825618,76.13099047,77.11784939,78.05835048]


def write_score():
    phrases=[
        ([71,73,75,78,75,73,71,68],[2.5,1.5,2,2,2.5,1.5,2,1.65]),
        ([68,71,73,75,78,75,73,71],[2,2,2.5,1.5,2.5,1.5,2,1.65]),
        ([71,75,78,75,73,71,68,66],[2.5,1.5,2.5,1.5,2,2,2,1.65]),
        ([68,71,73,75,73,71,68,71],[2,2,2.5,1.5,2,2,2,2])]
    events=[]
    for part,(pitches,durations) in enumerate(phrases):
        beat=part*16
        for note,(pitch,duration) in enumerate(zip(pitches,durations)):
            events.append({"instrument":"dizi","beat":beat,"midi":pitch,"duration_beats":duration,
                           "velocity":[78,80,85,90,86,82,78,74][note]+(2 if part==2 else 0),"articulation":"legato_body","phrase":part+1})
            beat+=duration
    support=[[59,59,63,66,63,61,59,59],[59,61,63,66,66,63,61,59],
             [63,66,66,63,61,59,59,59],[59,61,63,63,61,59,59,59]]
    for part,notes in enumerate(support):
        for index,pitch in enumerate(notes):
            beat=part*16+index*2
            events.append({"instrument":"dan_tranh","beat":beat,"midi":pitch,"duration_beats":min(2.6,64-beat),
                           "velocity":48+[0,2,4,5,3,1,-1,-3][index],"articulation":"tremolo","phrase":part+1})
    punctuations=[59,63,66,59,61,63,66,59,63,66,61,59,63,61,59,59]
    for bar,pitch in enumerate(punctuations):
        events.append({"instrument":"dan_tranh","beat":bar*4+(0.25 if bar%2==0 else 2.75),"midi":pitch,
                       "duration_beats":1,"velocity":52+(bar%4)*2,"articulation":"pluck","phrase":bar//4+1})
    for beat in [0,32]:events.append({"instrument":"gong","beat":beat,"midi":None,"duration_beats":2,"velocity":25,"articulation":"hit","phrase":int(beat/16)+1})
    track={"id":"continuous_exploration_v3","title_zh":"云径长歌","bpm":72,"bars":16,"time_signature":"4/4","tail_seconds":2.5,
           "events":sorted(events,key=lambda x:(x["beat"],x["instrument"])),"midi_ppq":480,"midi_tempo_us_per_quarter":833333,
           "phrases":[{"bars":[1,4],"role":"connected upward question and descending answer"},{"bars":[5,8],"role":"lower answer rising into the theme"},
                      {"bars":[9,12],"role":"higher expansion and descending turn"},{"bars":[13,16],"role":"long connected return and final cadence"}],
           "lead_rest_beats":1.05,"phrase_breath_beats":0.35,"legato_overlap_seconds":0.12,
           "note_event_counts":{key:sum(e["instrument"]==key for e in events) for key in ["dizi","dan_tranh","gong"]}}
    result={"status":"ONE_LAST_AUTONOMOUS_COMPOSITION_ATTEMPT","previous_v2_status":"USER_REJECTED_DISCONNECTED_MUSIC",
            "composition_credit":"New assistant-authored connected score, not old score with louder gain or echo; no music generation model.",
            "tracks":[track],"range":"Lead MIDI66..78, sample source67..78; no octave shift", "midi_role":"Score interchange; own sample map, not GM soundfont"}
    if SCORE.exists():raise SystemExit("Existing score preserved")
    SCORE.write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding="utf-8")


def fade(a,attack,release):
    result=a.copy()
    result[:,:attack]*=np.sin(np.linspace(0,np.pi/2,attack,dtype=np.float32))**2
    result[:,-release:]*=np.cos(np.linspace(0,np.pi/2,release,dtype=np.float32))**2
    return result


def render():
    track=json.loads(SCORE.read_text(encoding="utf-8"))["tracks"][0]
    OUT.mkdir(parents=True,exist_ok=True);RAW.mkdir(parents=True,exist_ok=True)
    if (OUT/"manifest.json").exists():raise SystemExit("Existing v3 preserved; no automatic further attempt")
    vcsl_path=ROOT/"assets/raw/audio/wuxia_original_trial_v2_20261009/sample_sources.json"
    source_map=json.loads(vcsl_path.read_text(encoding="utf-8"))["records"]
    dizi_path=ROOT/"assets/raw/audio/wuxia_original_samples_20261009/dizi/manifest.json"
    dizi=json.loads(dizi_path.read_text(encoding="utf-8"))
    dizi_rows=[{"id":"dizi_"+str(r["root_midi"]),"instrument":"dizi","style":"legato_body","root_midi":r["root_midi"],
                "estimated_midi_float":BODY_CENTERS[r["root_midi"]-67],"path":io.relative(Path(r["preview_path"])),"sha256":r["preview_sha256"],
                "actual_instrument":"Dizi-labelled public lossy preview; live recording provenance unverified","license":"CC0-1.0",
                "body_start_frame":BODY_START,"body_end_frame":BODY_END,"source_url":r["source_url"]} for r in dizi["samples"]]
    records=source_map+dizi_rows
    cache={};body_stats=[]
    for row in records:
        p=ROOT/row["path"]
        if io.sha(p)!=row["sha256"]:raise ValueError("Frozen source changed")
        a=io.decode(p)
        if row["instrument"]=="dizi":
            a=a[:,BODY_START:BODY_END]
            bins=np.array([np.sqrt(np.mean(a[:,i:i+2205].astype(np.float64)**2)) for i in range(0,a.shape[1]-2205+1,2205)])
            body_stats.append({"sample_id":row["id"],"source_sha256":row["sha256"],"start_frame":BODY_START,"end_frame":BODY_END,
                               "rms50ms_min":float(bins.min()),"rms50ms_max":float(bins.max()),"variation_db":float(20*np.log10(bins.max()/bins.min())),
                               "internal_silent_bins":int(np.sum(bins<bins.max()*0.1)),"body_estimated_midi_float":row["estimated_midi_float"]})
        cache[row["id"]]=a
    musical=64*60/72;frames=round((musical+2.5)*SR)
    dry={"dizi":np.zeros((2,frames),np.float32),"dan_tranh":np.zeros((2,frames),np.float32),"gong":np.zeros((2,frames),np.float32)}
    logs=[]
    for i,event in enumerate(track["events"]):
        rows=[r for r in records if r["instrument"]==event["instrument"] and r["style"]==event["articulation"]]
        row=rows[0] if event["midi"] is None else min(rows,key=lambda r:abs(r["root_midi"]-event["midi"]))
        semitones=0 if event["midi"] is None else event["midi"]-row.get("estimated_midi_float",row["root_midi"])
        ratio=2**(semitones/12);down=max(1,round(1000*ratio))
        original=cache[row["id"]]
        offset=0
        if event["articulation"]=="tremolo":offset=round((0.55+(i%5)*0.37)*SR);original=original[:,offset:]
        sample=signal.resample_poly(original,1000,down,axis=1).astype(np.float32)
        seconds=event["duration_beats"]*60/72
        nominal=event["beat"]*60/72
        if event["instrument"]=="dizi":
            leadin=min(.06,nominal);start=round((nominal-leadin)*SR)
            count=round((seconds+leadin+.06)*SR);attack=round(.12*SR);release=attack
            if sample.shape[1]<count:raise ValueError("Stable body too short; no raw repetition allowed")
            sample=sample[:,:count];level=.10*(event["velocity"]/84)
        elif event["articulation"]=="tremolo":
            start=round(nominal*SR);count=round(seconds*SR);sample=sample[:,:count]
            attack=round(.22*SR);release=round(.36*SR);level=.029*(event["velocity"]/50)
        elif event["instrument"]=="dan_tranh":
            start=round(nominal*SR);sample=sample[:,:round((seconds+1.5)*SR)]
            attack=88;release=round(.13*SR);level=.044*(event["velocity"]/54)
        else:
            start=round(nominal*SR);attack=88;release=round(.14*SR);level=.016
        source_rms=float(np.sqrt(np.mean(sample.astype(np.float64)**2)))
        sample_gain=level/max(source_rms,1e-12)
        sample=fade(sample,attack,release)*sample_gain
        pan=np.array([1,.94] if event["instrument"]=="dizi" else [.91,1],np.float32)[:,None]
        sample*=pan
        count=min(sample.shape[1],frames-start);dry[event["instrument"]][:,start:start+count]+=sample[:,:count]
        logs.append({"event_index":i,"sample_id":row["id"],"sample_sha256":row["sha256"],"root_midi":row["root_midi"],
                     "estimated_midi_float":row.get("estimated_midi_float"),"target_midi":event["midi"],"pitch_ratio":ratio,"resample_up":1000,"resample_down":down,
                     "source_offset_frames_after_body_selection":offset,"start_frame":start,"rendered_frames":count,"sample_gain":sample_gain,
                     "attack_frames":attack,"release_frames":release,"envelope":"sin_squared_attack/cos_squared_release","pan_gains":pan[:,0].tolist(),
                     "stable_body_used":event["instrument"]=="dizi","body_repeated_or_looped":False})
    dry_mix=np.zeros((2,frames),np.float32)
    for key,stem in dry.items():
        io.float_wav(OUT/("v3_stem_"+key+".wav"),stem);dry_mix+=stem
    delays=[(.019,.045),(.031,.035),(.047,.035),(.071,.025),(.101,.022),(.137,.017),(.181,.012),(.239,.010),(.307,.007),(.373,.004)]
    room=np.zeros_like(dry_mix)
    for i,(seconds,gain) in enumerate(delays):
        n=round(seconds*SR)
        channels=dry_mix[::-1] if i%2 else dry_mix
        room[:,n:]+=channels[:,:-n]*gain
    io.float_wav(OUT/"v3_stem_room_return.wav",room)
    wet=dry_mix+room
    raw_mix=RAW/"v3_original_mix_float.wav";io.float_wav(raw_mix,wet)
    raw_rms=float(np.sqrt(np.mean(wet.astype(np.float64)**2)));raw_peak=float(np.abs(wet).max())
    gain=min(10**(-22/20)/raw_rms,10**(-3/20)/raw_peak);listen=wet*gain
    edge=662;listen[:,:edge]*=np.linspace(0,1,edge,dtype=np.float32);listen[:,-edge:]*=np.linspace(1,0,edge,dtype=np.float32)
    wav=OUT/"v3_continuous_exploration_audition.wav";mp3=wav.with_suffix(".mp3")
    io.pcm_wav(wav,listen);io.mp3_file(mp3,listen)
    preview=listen[:,:20*SR].copy();preview[:,-2205:]*=np.linspace(1,0,2205,dtype=np.float32)
    pwav=OUT/"v3_first20s_audition.wav";pmp3=pwav.with_suffix(".mp3");io.pcm_wav(pwav,preview);io.mp3_file(pmp3,preview)
    midi=RAW/"v3_score.mid";io.midi_file(track,midi)
    bins=np.array([np.sqrt(np.mean(wet[:,i:i+4410].astype(np.float64)**2)) for i in range(0,round(musical*SR)-4410+1,4410)])
    manifest={"status":"LISTENING_PENDING","attempt_limit":"Only this final autonomous attempt; no automatic v4/v5","previous_v2_status":"USER_REJECTED",
              "script":io.info(Path(__file__)),"frozen_io_helpers":io.info(KERNEL),"score":io.info(SCORE),"midi":io.info(midi),"track":track,
              "source_map":io.info(vcsl_path),"source_records":records,"stable_body_observations":body_stats,"sample_render_events":logs,
              "sample_rate":SR,"channels":2,"musical_seconds":musical,"tail_seconds":2.5,"output_frames":frames,
              "room":{"algorithm":"Direct recorded stems + small delayed cross-channel reflections; no new oscillator or sustained synth pad",
                      "delay_seconds_gain":delays,"rounding":"round(seconds*44100)","alternating_cross_channel":True,"wet_gain_separate":1},
              "mixing":{"stem_order":["dizi","dan_tranh","gong","room_return"],"float32_add_order":"dry=0+dizi+dan_tranh+gong;wet=dry+room_return",
                         "raw_mix":io.info(raw_mix),"linear_gain":gain,"target_rms_dbfs":-22,"peak_cap_dbfs":-3,
                         "peak_cap_limited":10**(-3/20)/raw_peak<10**(-22/20)/raw_rms,"edge_fade_frames":edge,"quantization":"trunc_int16","pcm_scale":32767,
                         "actual_rms_dbfs":20*math.log10(float(np.sqrt(np.mean(listen.astype(np.float64)**2)))),"actual_peak":float(np.abs(listen).max())},
              "preview":{"source":"First882000frames of full floating audition","frames":20*SR,"last_fade_frames":2205},
              "coverage":{"musical100ms_bins":len(bins),"bins_below_minus20db_relative_rms":int(np.sum(bins<bins.max()*.1)),
                          "note":"Energy continuity observation only; musical coherence still requires user listening"},
              "outputs":[io.info(p) for p in sorted(OUT.iterdir()) if p.is_file()]+[io.info(raw_mix)],
              "music_generation_model_called":False,"formal_game_adopted":False,"loop_approval":False}
    (OUT/"manifest.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding="utf-8")
    print("V3_READY",frames/SR,manifest["mixing"],manifest["coverage"],flush=True)


def main():
    p=argparse.ArgumentParser();p.add_argument("--write-score",action="store_true");args=p.parse_args()
    if args.write_score:write_score()
    else:render()


if __name__=="__main__":main()
