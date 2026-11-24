"""Assistant-authored scores played offline with licensed single-note recordings.

No music generation model, no old music/sample lifting, no synthesized oscillators.
Names preserve actual source instruments. MIDI is a score interchange artifact;
the audio uses the explicit sample map, never an implicit GM soundfont.
"""
from pathlib import Path
import argparse
import concurrent.futures
import hashlib
import json
import math
import shutil
import struct
import subprocess
import urllib.request
import urllib.parse
import wave
import numpy as np
import av
from scipy import signal

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "assets/raw/audio/wuxia_original_trial_20261009"
OUT = ROOT / "assets/processed/audio/wuxia_original_trial_20261009"
SCORE_PATH = Path(__file__).with_name("wuxia_original_trial_score_20261009.json")
VCSL = ROOT / "tools/audio/VCSL-source"
REV = "c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e"
BASE = "https://raw.githubusercontent.com/sgossner/VCSL/" + REV + "/"
SR = 44100


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def relative(path):
    return str(path.relative_to(ROOT)).replace("\\", "/")


def info(path):
    return {"path": relative(path), "size": path.stat().st_size, "sha256": sha(path)}


def decode(path):
    with av.open(str(path)) as c:
        r = av.AudioResampler(format="fltp", layout="stereo", rate=SR)
        a = [f.to_ndarray() for d in c.decode(audio=0) for f in r.resample(d)]
        a.extend(f.to_ndarray() for f in r.resample(None))
    return np.concatenate(a, axis=1).astype(np.float32)


def sample_specs():
    rows = []
    notes = {"B3":59, "C#3":49, "D#3":51, "F#3":54, "G#3":56,
             "B4":71, "C#4":61, "D#4":63, "F#4":66, "G#4":68}
    # B3 corrected below follows scientific pitch notation: MIDI B3 = 59.
    for note, midi in notes.items():
        rows.append({"id":"dan_"+note, "instrument":"dan_tranh", "actual_instrument":"Vietnamese đàn tranh zither",
                     "root_midi":midi, "style":"pluck", "repo_path":f"Chordophones/Zithers/Dan Tranh/Normal/{note}_mf_1.wav"})
    for note, midi in [("B3",59),("D#3",51),("F#3",54),("B4",71)]:
        rows.append({"id":"dan_trem_"+note, "instrument":"dan_tranh", "actual_instrument":"Vietnamese đàn tranh zither",
                     "root_midi":midi, "style":"tremolo", "repo_path":f"Chordophones/Zithers/Dan Tranh/Tremolo/{note}_Trem_1.wav"})
    for key, instrument, path in [
        ("gong_soft","gong","Idiophones/Struck Idiophones/Gong 1/gong_p.wav"),
        ("gong_medium","gong","Idiophones/Struck Idiophones/Gong 1/gong_mf.wav"),
        ("wood_soft1","woodblock","Idiophones/Struck Idiophones/Woodblock/wood_click_pp_rr1.wav"),
        ("wood_soft2","woodblock","Idiophones/Struck Idiophones/Woodblock/wood_click_pp_rr2.wav"),
        ("wood_medium","woodblock","Idiophones/Struck Idiophones/Woodblock/wood_click_mp.wav"),
        ("drum_medium1","bass_drum","Membranophones/Struck Membranophones/Bass Drum 2/bassdrum_hit_mf1.wav"),
        ("drum_medium2","bass_drum","Membranophones/Struck Membranophones/Bass Drum 2/bassdrum_hit_mf2.wav"),
        ("drum_soft","bass_drum","Membranophones/Struck Membranophones/Bass Drum 2/bassdrum_hit_mp1.wav")]:
        rows.append({"id":key,"instrument":instrument,"actual_instrument":instrument.replace("_"," "),
                     "root_midi":None,"style":"hit","repo_path":path})
    return rows


def prepare_samples():
    RAW.mkdir(parents=True, exist_ok=True)
    tree = subprocess.check_output(["git","-C",str(VCSL),"ls-tree","-r","-z","HEAD"])
    hashes = {entry.split(b"\t",1)[1].decode():entry.split(b"\t",1)[0].split()[2].decode()
              for entry in tree.split(b"\0") if entry}
    rows = sample_specs()
    def obtain(item):
        name = item["repo_path"]
        target = RAW / "samples/vcsl" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            with urllib.request.urlopen(BASE+urllib.parse.quote(name), timeout=60) as response:
                data=response.read()
            git_hash = hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
            if git_hash != hashes[name]:
                raise ValueError("Pinned Git blob mismatch: "+name)
            target.write_bytes(data)
        data=target.read_bytes()
        actual=hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
        if actual!=hashes[name]:
            raise ValueError("Existing sample changed: "+name)
        return {**item,**info(target),"url":BASE+urllib.parse.quote(name),"git_blob_sha1":actual,"license":"CC0-1.0"}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        records=list(pool.map(obtain,rows))
    for name in ["README.md","LICENSE"]:
        target=RAW/("VCSL_"+name)
        if not target.exists():
            with urllib.request.urlopen(BASE+name,timeout=45) as r: target.write_bytes(r.read())
    manifest={"source_repository":"https://github.com/sgossner/VCSL","revision":REV,"license":"CC0-1.0",
              "commercial_use":"CC0 dedication permits commercial sample use; real instrument identity retained.",
              "records":records,"license_files":[info(RAW/"VCSL_README.md"),info(RAW/"VCSL_LICENSE")]}
    (RAW/"sample_sources.json").write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding="utf-8")
    print("SAMPLES_READY",len(records),sum(x["size"] for x in records),flush=True)


def vlq(number):
    a=[number&127]
    while number>>7:
        number>>=7;a.insert(0,(number&127)|128)
    return bytes(a)


def midi_file(track, path):
    chunks=[]
    tempo=round(60000000/track["bpm"])
    conductor=b"\0\xff\x51\x03"+tempo.to_bytes(3,"big")+b"\0\xff\x58\x04\x04\x02\x18\x08"
    conductor+=vlq(track["bars"]*4*480)+b"\xff\x2f\0"
    chunks.append(conductor)
    channels={"dizi":0,"dan_tranh":1,"bass_drum":9,"gong":9,"woodblock":9}
    percussion={"bass_drum":35,"gong":52,"woodblock":76}
    for instrument in ["dizi","dan_tranh","bass_drum","gong","woodblock"]:
        events=[]
        for event in track["events"]:
            if event["instrument"]!=instrument:continue
            note=event["midi"] if event["midi"] is not None else percussion[instrument]
            start=round(event["beat"]*480);end=round((event["beat"]+event["duration_beats"])*480)
            events.extend([(start,1,bytes([0x90|channels[instrument],note,event["velocity"]])),
                           (end,0,bytes([0x80|channels[instrument],note,0]))])
        label=instrument.encode();data=b"\0\xff\x03"+vlq(len(label))+label
        prev=0
        for tick,_,message in sorted(events):data+=vlq(tick-prev)+message;prev=tick
        data+=vlq(max(0,track["bars"]*4*480-prev))+b"\xff\x2f\0"
        chunks.append(data)
    path.write_bytes(b"MThd"+struct.pack(">IHHH",6,1,len(chunks),480)+b"".join(b"MTrk"+struct.pack(">I",len(c))+c for c in chunks))


def write_score():
    """The following phrase notes/rhythms are newly authored, not model outputs."""
    def event(inst, beat, pitch, duration, velocity, articulation):
        return {"instrument":inst,"beat":beat,"midi":pitch,"duration_beats":duration,"velocity":velocity,"articulation":articulation}
    # Four independent four-bar melodic sentences. Tuple: beat in bar, MIDI, hold beats.
    exploration=[
        [(0,71,1.25),(2,75,.75),(3,78,.5)],[(.5,78,1.5),(2.5,75,.75),(3.5,73,.25)],
        [(0,71,.75),(1.5,68,.5),(2.5,66,1)],[(.5,71,2.5)],
        [(0,73,.75),(1.25,75,.5),(2.5,78,1)],[(.25,80,.5),(1.5,78,1),(3,75,.5)],
        [(0,73,1.25),(2,68,.75)],[(1,71,2)],
        [(0,78,1),(1.75,80,.5),(3,83,.5)],[(.5,80,1),(2,78,.75),(3.25,75,.5)],
        [(0,73,.75),(1.5,75,1),(3,71,.5)],[(.75,68,1.5)],
        [(0,75,.75),(1.5,73,.5),(2.75,71,.75)],[(.5,68,1),(2,66,1)],
        [(0,68,.75),(1.5,71,1.25)],[(.5,71,2.5)]]
    ee=[]
    for bar, notes in enumerate(exploration):
        for n,(beat,pitch,dur) in enumerate(notes):ee.append(event("dizi",bar*4+beat,pitch,dur,70+[0,6,-3,2][bar%4]+n*2,"sustain"))
    # Sparse punctuation, not a repeating accompaniment arpeggio.
    for beat,pitch,dur,v in [(0,59,1,56),(3.25,66,.75,51),(7,63,1,58),(8.25,56,1,47),(13.5,59,1,60),
                            (16,61,1,57),(18.75,68,.7,46),(22,63,1,54),(26.5,59,1,50),(30,59,1.5,57),
                            (32,66,1,65),(35.5,71,.5,49),(38,68,.75,61),(42.5,63,1,54),(46,56,1.5,45),
                            (48,63,1,61),(51,59,1,53),(54.5,54,1,42),(58,56,1,47),(62,59,1.5,57)]:ee.append(event("dan_tranh",beat,pitch,dur,v,"pluck"))
    for beat in [11.5,27.25,43.5]:ee.append(event("woodblock",beat,None,.25,34,"hit"))
    ee.append(event("gong",32,None,2,30,"hit"))
    # Four six-bar combat paragraphs, developing the exploratory motif.
    combat=[
        [(0,71,.5),(.75,75,.5),(2,78,.75)],[(0,78,.5),(1.5,75,.5),(2.75,73,.5)],
        [(.25,71,.5),(1.25,68,.5),(3,66,.5)],[(0,71,1),(2.5,75,.5)],[(.5,78,1.25)],[],
        [(0,73,.5),(.75,75,.5),(2,78,.5),(3.25,80,.25)],[(0,78,.75),(1.5,75,.5),(3,73,.5)],
        [(.5,68,.5),(1.75,71,.75)],[(0,75,.5),(1,78,.5),(2.5,75,.5)],[(0,73,1.25),(2.75,71,.5)],[],
        [(0,78,.5),(.75,80,.5),(2,83,.5),(3,80,.5)],[(.5,78,.5),(1.5,75,.5),(3,73,.5)],
        [(0,75,.75),(1.5,78,.5),(2.75,80,.5)],[(0,83,.75),(2,80,.5),(3.25,78,.25)],
        [(.25,75,.5),(1.25,73,.5),(2.75,71,.75)],[],
        [(0,75,.5),(.75,73,.5),(2,71,.75)],[(.5,68,.5),(1.75,66,.75)],
        [(0,68,.5),(1.25,71,.75),(3,75,.5)],[(0,78,.5),(1.25,75,.5),(2.75,73,.5)],
        [(.25,71,1.5)],[(0,71,2)]]
    ce=[]
    for bar,notes in enumerate(combat):
        for n,(beat,pitch,dur) in enumerate(notes):ce.append(event("dizi",bar*4+beat,pitch,dur,82+[0,3,-4,6,-2,-8][bar%6]+n,"sustain"))
        # Different six-bar paragraphs: call, response, build, release.
        pitches=[[59,63,66],[61,63,68],[66,68,71],[63,59,54]][bar//6]
        rhythm=[(0,.5),(1.75,.4),(3.25,.4)] if bar%3!=2 else [(.5,.5),(2.5,.6)]
        if bar in (5,11,17):rhythm=[(.25,1.25),(2.75,.5)]
        for n,(b,d) in enumerate(rhythm):
            articulation="tremolo" if bar in (4,10,16,20) and n==0 else "pluck"
            ce.append(event("dan_tranh",bar*4+b,pitches[n%len(pitches)],d,78+[0,8,-5][n%3],articulation))
        drum_rhythms=[[(0,82),(1.5,60),(3.25,67)],[(.25,65),(2,80)],[(0,76),(2.75,61)],[(0,85),(1.75,62),(3.5,70)]]
        pattern=drum_rhythms[(bar+bar//6)%4]
        if bar in (5,11,17):pattern=[(0,64),(3.5,44)]
        for b,v in pattern:ce.append(event("bass_drum",bar*4+b,None,.5,v,"hit"))
        if bar%2==1:ce.append(event("woodblock",bar*4+2.5,None,.2,44+(bar%4)*4,"hit"))
    for b,v in [(0,57),(24,46),(48,63),(72,48),(92,40)]:ce.append(event("gong",b,None,2,v,"hit"))
    tracks=[{"id":"original_exploration","title_zh":"山径问云","bpm":80,"bars":16,"time_signature":"4/4","tail_seconds":2,
             "phrases":[{"bars":[1,4],"role":"short ascending question, descending answer and rest"},{"bars":[5,8],"role":"middle register answer with altered rhythm"},
                        {"bars":[9,12],"role":"higher-register opening and wider pauses"},{"bars":[13,16],"role":"descending resolution, sparse zither punctuation"}],"events":sorted(ee,key=lambda e:(e["beat"],e["instrument"]))},
            {"id":"original_combat","title_zh":"临风试锋","bpm":128,"bars":24,"time_signature":"4/4","tail_seconds":2.5,
             "phrases":[{"bars":[1,6],"role":"clipped question and sparring response"},{"bars":[7,12],"role":"syncopated answer with one flute-rest bar"},
                        {"bars":[13,18],"role":"higher tension, short tremolo accents, contrasted silence"},{"bars":[19,24],"role":"lower resolution and final held answer"}],"events":sorted(ce,key=lambda e:(e["beat"],e["instrument"]))}]
    for track in tracks:
        track["midi_ppq"]=480;track["midi_tempo_us_per_quarter"]=round(60000000/track["bpm"])
        track["note_event_counts"]={inst:sum(e["instrument"]==inst for e in track["events"]) for inst in ["dizi","dan_tranh","bass_drum","gong","woodblock"]}
        track["lead_rest_beats"]=track["bars"]*4-sum(e["duration_beats"] for e in track["events"] if e["instrument"]=="dizi")
    result={"composer_credit":"Assistant independently authored new pitches, phrases and rhythms, not a music generation model and not a human composer performance.",
            "tonal_plan":"B major pentatonic: B C# D# F# G#; new shared motif varied between exploration and combat.",
            "instrument_identity":"VCSL Vietnamese Dan Tranh, bass drum, gong and woodblock; public uploader Dizi-labelled single notes have unverified acoustic recording origin.",
            "midi_role":"Score interchange only; instrument names retained. No GM soundfont is used for rendering; percussion notes35/52/76 map via sample records.","tracks":tracks}
    if SCORE_PATH.exists():raise SystemExit("Existing score preserved")
    SCORE_PATH.write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding="utf-8")
    print("SCORE_READY",[(t["id"],t["note_event_counts"],t["lead_rest_beats"]) for t in tracks],flush=True)


def float_wav(path,audio):
    payload=audio.T.astype("<f4").tobytes()
    header=struct.pack("<4sI4s4sIHHIIHH4sI",b"RIFF",36+len(payload),b"WAVE",b"fmt ",16,3,2,SR,SR*8,8,32,b"data",len(payload))
    path.write_bytes(header+payload)


def pcm_wav(path,audio):
    pcm=(audio.T*32767).astype("<i2")
    with wave.open(str(path),"wb") as f:
        f.setparams((2,2,SR,0,"NONE","not compressed"));f.writeframes(pcm.tobytes())


def mp3_file(path,audio):
    with av.open(str(path),"w") as c:
        stream=c.add_stream("libmp3lame",rate=SR);stream.bit_rate=192000;stream.layout="stereo"
        for pos in range(0,audio.shape[1],1152):
            f=av.AudioFrame.from_ndarray(np.ascontiguousarray(audio[:,pos:pos+1152]),format="fltp",layout="stereo");f.sample_rate=SR
            for p in stream.encode(f):c.mux(p)
        for p in stream.encode(None):c.mux(p)


def render():
    score=json.loads(SCORE_PATH.read_text(encoding="utf-8"))
    sources=json.loads((RAW/"sample_sources.json").read_text(encoding="utf-8"))
    external=ROOT/"assets/raw/audio/wuxia_original_samples_20261009/dizi/manifest.json"
    if not external.exists():raise SystemExit("Dizi source manifest not ready; no substitute mislabeled as flute")
    dizi=json.loads(external.read_text(encoding="utf-8"))
    # Research provides actual decoded single-note maps in records.
    dizi_records=[{"id":"dizi_"+str(r["root_midi"]),"instrument":"dizi","actual_instrument":"Uploader Dizi-labelled single-note sample; acoustic/live origin unverified",
                   "root_midi":r["root_midi"],"estimated_midi_float":r["pitch_analysis"]["estimated_midi_float"],"style":"sustain",
                   "path":relative(Path(r["preview_path"])),"sha256":r["preview_sha256"],"source_format":"Public lossy OGG preview, decoded directly to float; clipped convenience PCM16 WAV not used",
                   "license":r["license"],"source_url":r["source_url"],"preview_url":r["preview_url"],"source_html_path":r["source_html_path"]} for r in dizi["samples"]]
    if len(dizi_records)<10:raise SystemExit("Dizi source pack still in progress; wait for complete fixed source map")
    records=sources["records"]+dizi_records
    cache={}
    for row in records:
        p=ROOT/row["path"]
        if sha(p)!=row["sha256"]:raise ValueError("Source SHA changed: "+str(p))
        audio=decode(p)
        peak=float(np.abs(audio).max())
        active=np.flatnonzero(np.max(np.abs(audio),axis=0)>=peak*0.008)
        onset=max(0,int(active[0])-88) if len(active) else 0
        cache[row["id"]]=(audio[:,onset:],onset,peak)
    OUT.mkdir(parents=True,exist_ok=True)
    manifests=[]
    for track in score["tracks"]:
        name=track["id"]
        if (OUT/(name+".processing.json")).exists():raise SystemExit("Preserving existing render: "+name)
        musical_seconds=track["bars"]*4*60/track["bpm"]
        frames=round((musical_seconds+track["tail_seconds"])*SR)
        stems={key:np.zeros((2,frames),np.float32) for key in ["dizi","dan_tranh","bass_drum","gong","woodblock"]}
        logs=[]
        for index,event in enumerate(track["events"]):
            available=[r for r in records if r["instrument"]==event["instrument"] and r["style"]==event["articulation"]]
            if not available:raise ValueError("No truthful source mapping for "+str(event))
            if event["midi"] is None:
                row=available[index%len(available)]
            else:row=min(available,key=lambda r:abs(r["root_midi"]-event["midi"]))
            original,onset,peak=cache[row["id"]]
            semitones=0 if event["midi"] is None else event["midi"]-row.get("estimated_midi_float",row["root_midi"])
            ratio=2**(semitones/12)
            # Resampling changes recorded sample pitch and length; not a synthesis oscillator.
            sample=signal.resample_poly(original,1000,max(1,round(1000*ratio)),axis=1).astype(np.float32)
            hold=event["duration_beats"]*60/track["bpm"]
            if event["instrument"]=="dizi" or event["articulation"]=="tremolo":maxlen=round((hold+0.08)*SR)
            elif event["instrument"]=="dan_tranh":maxlen=round((hold+1.2)*SR)
            else:maxlen=sample.shape[1]
            sample=sample[:,:maxlen].copy()
            release=min(round(0.07*SR),sample.shape[1]//3)
            attack=min(88,sample.shape[1]//3)
            sample[:,:attack]*=np.linspace(0,1,attack,dtype=np.float32)
            sample[:,-release:]*=np.linspace(1,0,release,dtype=np.float32)
            base={"dizi":0.23,"dan_tranh":0.20,"bass_drum":0.20,"gong":0.10,"woodblock":0.085}[event["instrument"]]
            gain=base*(event["velocity"]/100)**1.2/max(peak,1e-12)
            pan={"dizi":0.10,"dan_tranh":-0.18,"bass_drum":0,"gong":-0.1,"woodblock":0.22}[event["instrument"]]
            pan_gains=np.array([min(1,1-pan),min(1,1+pan)],np.float32)[:,None]
            sample=sample*gain*pan_gains
            start=round(event["beat"]*60/track["bpm"]*SR)
            n=min(sample.shape[1],frames-start)
            stems[event["instrument"]][:,start:start+n]+=sample[:,:n]
            logs.append({"event_index":index,"sample_id":row["id"],"sample_sha256":row["sha256"],"root_midi":row["root_midi"],
                         "target_midi":event["midi"],"semitones":semitones,"pitch_ratio":ratio,"resample_up":1000,"resample_down":round(1000*ratio),
                         "source_onset_frames":onset,"start_frame":start,"rendered_frames":n,"sample_gain":gain,"pan_gains":pan_gains[:,0].tolist(),
                         "attack_frames":attack,"release_frames":release})
        mixed=np.zeros((2,frames),np.float32)
        for key,stem in stems.items():
            float_wav(OUT/(name+"_stem_"+key+".wav"),stem)
            mixed+=stem
        rawmix=RAW/(name+"_original_mix_float.wav");float_wav(rawmix,mixed)
        raw_rms=float(np.sqrt(np.mean(mixed.astype(np.float64)**2)));raw_peak=float(np.abs(mixed).max())
        gain=min(10**(-22/20)/raw_rms,10**(-3/20)/raw_peak)
        listen=mixed*gain
        edge=min(round(0.015*SR),frames//2)
        listen[:,:edge]*=np.linspace(0,1,edge,dtype=np.float32)
        listen[:,-edge:]*=np.linspace(1,0,edge,dtype=np.float32)
        wav=OUT/(name+"_audition.wav");mp3=wav.with_suffix(".mp3")
        pcm_wav(wav,listen);mp3_file(mp3,listen)
        midi=RAW/(name+"_score.mid");midi_file(track,midi)
        result={"status":"LISTENING_PENDING","composition_credit":"Assistant independently authored score; not human-performed composition, not model-generated music.",
                "score":info(SCORE_PATH),"track":track,"sample_records":records,"sample_render_events":logs,
                "musical_seconds":musical_seconds,"tail_seconds":track["tail_seconds"],"output_frames":frames,"sample_rate":SR,"channels":2,
                "mixing":{"stem_order":list(stems),"raw_mix_is_sum_of_float32_stems":True,"raw_mix":info(rawmix),"linear_gain":gain,
                           "target_rms_dbfs":-22,"peak_cap_dbfs":-3,"peak_cap_limited":10**(-3/20)/raw_peak<10**(-22/20)/raw_rms,
                           "actual_rms_dbfs":20*math.log10(float(np.sqrt(np.mean(listen.astype(np.float64)**2)))),
                           "actual_peak":float(np.abs(listen).max()),"edge_fade_frames":edge,"quantization":"trunc_int16","pcm_scale":32767},
                "midi":info(midi),"outputs":[info(p) for p in sorted(OUT.glob(name+"*.wav"))]+[info(mp3)],
                "melody_source":"New written motif/phrases in explicit score, no old approved audio or existing tune sampled.",
                "model_called":False,"runtime_adopted":False,"loop_review":"Not requested; examples have a natural ending."}
        (OUT/(name+".processing.json")).write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding="utf-8")
        manifests.append(result);print("ORIGINAL_READY",name,frames/SR,result["mixing"],flush=True)
    (OUT/"manifest.json").write_text(json.dumps({"status":"LISTENING_PENDING","script":info(Path(__file__)),"score":info(SCORE_PATH),
                    "sources":sources,"dizi_sources":dizi,"tracks":manifests,"no_music_generation_model":True},indent=2,ensure_ascii=False),encoding="utf-8")


def main():
    parser=argparse.ArgumentParser();parser.add_argument("--prepare-samples",action="store_true");parser.add_argument("--write-score",action="store_true");args=parser.parse_args()
    if args.prepare_samples:prepare_samples()
    elif args.write_score:write_score()
    else:render()


if __name__=="__main__":main()
