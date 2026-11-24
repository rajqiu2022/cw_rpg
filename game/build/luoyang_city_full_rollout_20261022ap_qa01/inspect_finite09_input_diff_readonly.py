"""Print typed source differences; no stage import/execution or writes."""
import json
from pathlib import Path
P = Path(__file__).resolve().parents[2] / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
a = json.loads((P/'finite08_input01_ROOT_LOCKED.json').read_bytes())
b = json.loads((P/'finite09_input01_ROOT_LOCKED.json').read_bytes())
def walk(a,b,path=()):
    if type(a) is not type(b):
        print(path,repr(a),repr(b));return
    if isinstance(a,dict):
        for k in sorted(a.keys()|b.keys()):
            if k not in a or k not in b: print(path+(k,),repr(a.get(k)),repr(b.get(k)))
            else: walk(a[k],b[k],path+(k,))
    elif isinstance(a,list):
        if len(a)!=len(b):print(path,'LENGTH',len(a),len(b))
        for i,(x,y) in enumerate(zip(a,b)):walk(x,y,path+(i,))
    elif a!=b:print(path,repr(a),repr(b))
walk(a,b)
