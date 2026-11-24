"""One exact count-type correction to unexecuted Root JSON copy transport; no Stage or canonical writes."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
parent=N/'copy_Field_EOF24_JSON14_after_GD10_ROOT_ONLY.py'
old=parent.read_bytes();digest=lambda b:hashlib.sha256(b).hexdigest()
assert digest(old)=='83faf8dd0d209f4535fd6af314210a747a30b074501597b63402331f8d5c5d58'
a=b"backup['media_content_changes']==[]"
b=b"(type(backup['media_content_changes'])is int and backup['media_content_changes']==0)"
assert old.count(a)==1
new=old.replace(a,b,1);assert new.replace(b,a,1)==old
dest=N/'copy_Field_EOF24_JSON14_after_GD10_ROOT_ONLY03.py';assert not dest.exists()
compile(new.decode('utf8'),str(dest),'exec')
with dest.open('xb')as f:f.write(new)
proof=dict(parent=dict(path='res://build/luoyang_city_finish_20261025i_source01/'+parent.name,sha256=digest(old),bytes=len(old)),candidate=dict(path='res://build/luoyang_city_finish_20261025i_source01/'+dest.name,sha256=digest(new),bytes=len(new)),hunks=[dict(old=a.decode(),new=b.decode())],whole_UTF8_forward_inverse=True,only_media_content_change_count_type_fix=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
raw=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode('utf8')
out=N/'Field_EOF_adoption01/copy03_count_type_whole_inverse_NOT_STAGE.json';assert not out.exists()
with out.open('xb')as f:f.write(raw)
print(json.dumps(dict(candidate=proof['candidate'],proof=dict(path='res://build/luoyang_city_finish_20261025i_source01/Field_EOF_adoption01/'+out.name,sha256=digest(raw),bytes=len(raw)))))
