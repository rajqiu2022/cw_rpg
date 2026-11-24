"""One fixed Temple new-route set only; no engine, output writes, or anchor search."""
from pathlib import Path
import hashlib,json,math
BASE=Path(__file__).resolve().parent
helper=BASE/'two_outdoor_residuals07_READONLY.py'
assert hashlib.sha256(helper.read_bytes()).hexdigest()=='78148bfe1d0f6d44a7b018d993b5fc812aabdaaf950ed40adfc7588e889cd18f'
text=helper.read_text(encoding='utf-8'); exec(text[:text.index("E=A['regions']")])
path=N/'regions_author04_two_courts_residual_BUILD.json'
assert hashlib.sha256(path.read_bytes()).hexdigest()=='f71e25e30236bc914ba119efdf1f240dedf04b8fbb612e09ce0ddac1dce2d67b'
A=json.loads(path.read_text(encoding='utf-8-sig'))
M=A['regions']['luoyang_temple_region_27d'];MS=geometry(M)

def examine(points):
    failures=[];total=0
    for segment,(a,b) in enumerate(zip(points,points[1:])):
        count=max(1,math.ceil(math.dist(a,b)));first=None
        for j in range(count+1):
            p=[a[i]+(b[i]-a[i])*j/count for i in range(2)]; total+=1
            detail=inspect(M,MS,p)
            if first is None and (not detail['ground_covers'] or detail['solid_hits'] or detail['NPC_hits']):
                first={'segment_index':segment,'segment':[a,b],'step':j,'detail':detail}
        if first:failures.append(first)
    return {'passed':not failures,'one_pixel_samples':total,'first_bad_per_segment':failures}

old={r['id']:examine(r['points_px']) for r in M['routes']}
proposed={
 'temple_paper_turnin':[[1536,3180],[1536,3100],[2000,3100],[2000,3200]]
}
print(json.dumps({'old_routes':old,'unique_proposed':{k:{'points_px':v,'check':examine(v)} for k,v in proposed.items()},'scope':'Independent double precision diagnostic for the current Temple authored route set only; Source compiler authoritative, no old-world/owner/art revalidation.'},ensure_ascii=False,indent=2))
