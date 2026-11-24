from pathlib import Path
from PIL import Image
import hashlib,json,math,random,wave,struct
ROOT=Path('F:/Code/RPG_GAME'); RAW=ROOT/'assets/raw/gather_actions_20261030l'
OUT=ROOT/'game/art/sprites/life_skills_20261030l'; AUDIO=ROOT/'game/art/audio/life_skills_20261030l'
AUDIO.mkdir(parents=True,exist_ok=True)
rows=[]; actions={}
for name,kind,feet,scale,duration in [
 ('gather_herb_right_4f','herb',[(280,617),(280,616),(260,612),(278,616)],128.52/514,1.2),
 ('mine_ore_right_4f','ore',[(240,656),(272,656),(240,655),(242,656)],128.52/505,1.5)]:
    src=RAW/(name+'.png'); image=Image.open(src).convert('RGBA'); w,h=image.size; cw=w//4; pad=32
    result=Image.new('RGBA',(4*(cw+64),h+64),(0,0,0,0)); removed=0; boxes=[]; frames=[]
    for index in range(4):
        frame=image.crop((index*cw,0,(index+1)*cw,h)); a=frame.getchannel('A')
        box=a.point(lambda v:255 if v>=128 else 0).getbbox()
        protect=(max(0,box[0]-32),max(0,box[1]-32),min(cw,box[2]+32),min(h,box[3]+32))
        px=frame.load()
        for y in range(h):
            for x in range(cw):
                rgba=px[x,y]
                if rgba[3]==1 and not(protect[0]<=x<protect[2] and protect[1]<=y<protect[3]):
                    px[x,y]=(rgba[0],rgba[1],rgba[2],0); removed+=1
        result.paste(frame,(index*(cw+64)+pad,pad))
        # The complete original cell's RGB is preserved; only authorized outside A1 changes.
        before=image.crop((index*cw,0,(index+1)*cw,h))
        assert before.convert('RGB').tobytes()==frame.convert('RGB').tobytes()
        assert before.crop(protect).tobytes()==frame.crop(protect).tobytes()
        boxes.append({'frame':index,'subject128_box':box,'protection_box':protect})
        frames.append({'rect':[index*(cw+64),0,cw+64,h+64],'source_foot':[feet[index][0]+pad,feet[index][1]+pad],'scale':scale})
    target=OUT/(name+'_padded.png');result.save(target)
    audio='herb_rustle_pluck.wav' if kind=='herb' else 'pickaxe_stone_hit.wav'
    actions[kind]={'sheet':'res://art/sprites/life_skills_20261030l/'+target.name,'duration':duration,'frames':frames,'cues':[{'frame':2,'path':'res://art/audio/life_skills_20261030l/'+audio,'volume_db':-3}],'left_is_runtime_mirror':True}
    rows.append({'name':name,'raw_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'source_size':[w,h],'processed_size':list(result.size),'processed_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'removed_outside_alpha1_only':removed,'all_original_RGB_preserved':True,'protection_RGBA_preserved':True,'frame_boxes':boxes,'no_resampling_or_repainting':True})
rate=48000
def smooth_noise(count,rng,cutoff):
    out=[]; state=0.0; k=1-math.exp(-2*math.pi*cutoff/rate)
    for _ in range(count):
        state+=k*(rng.uniform(-1,1)-state);out.append(state)
    return out
def save_sound(name,samples,description):
    peak=max(abs(v) for v in samples); samples=[v*(.72/peak) for v in samples]
    path=AUDIO/name
    with wave.open(str(path),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
        f.writeframes(b''.join(struct.pack('<h',max(-32767,min(32767,round(v*32767)))) for v in samples))
    return {'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'rate':rate,'channels':1,'seconds':len(samples)/rate,'peak':max(abs(v) for v in samples),'rms':math.sqrt(sum(v*v for v in samples)/len(samples)),'source':'deterministic offline procedural sound design; not recorded or AI-generated','description':description,'listened':False}
rng=random.Random(30101);n=int(rate*.52)
low=smooth_noise(n,rng,850);high=smooth_noise(n,rng,6500);leaf=[]
for i in range(n):
    t=i/rate
    rub=sum(math.exp(-((t-c)/s)**2) for c,s in [(.055,.027),(.12,.035),(.225,.040),(.315,.026)])
    rub*=min(1,t/.012)*math.exp(-t*2)
    pluck=math.exp(-max(0,t-.29)*85)*math.sin(2*math.pi*170*max(0,t-.29)) if t>=.29 else 0
    leaf.append((high[i]-low[i])*.75*rub+.12*pluck)
rng=random.Random(30102);n=int(rate*.55)
noise=smooth_noise(n,rng,8800);rock=[]
for i in range(n):
    t=i/rate
    body=.62*math.exp(-t*62)*noise[i]
    ring=(math.sin(2*math.pi*1230*t)*math.exp(-t*32)+.38*math.sin(2*math.pi*2477*t)*math.exp(-t*48))*.15
    thud=.4*math.sin(2*math.pi*(145*t-90*t*t))*math.exp(-t*42)
    grit=sum(.18*math.exp(-max(0,t-c)*90)*noise[i] for c in [.046,.089,.151] if t>=c)
    rock.append((body+ring+thud+grit)*min(1,t/.001))
audio=[save_sound('herb_rustle_pluck.wav',leaf,'Three dry leaf friction bursts and a short fibrous pluck; no notes or UI chime.'),save_sound('pickaxe_stone_hit.wav',rock,'Short mineral crack, restrained iron resonance and settling grit, one strike; no sword clash or music.')]
(ROOT/'game/scripts/life_skills/gathering_actions_20261030l.json').write_text(json.dumps({'schema_version':1,'actions':actions},indent=2)+'\n',encoding='utf-8')
(ROOT/'game/build/gather_actions_20261030l_root01/assets_prepared_ACTUAL.json').write_text(json.dumps({'sheets':rows,'audio':audio},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'sheets':[(r['name'],r['processed_size'],r['removed_outside_alpha1_only']) for r in rows],'audio':[(a['path'],a['seconds']) for a in audio]}))
