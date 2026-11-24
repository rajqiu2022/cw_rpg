from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;P=N/'gate_texture_repair01/market_portal_payload_ROOT_READY';NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
spec=dict(ready=True,status='ROOT_AUTHORIZED_ONE_MARKET_POST24E_PORTAL_SOURCE_SUCCESSOR_NO_GEOMETRY',payload=dict(path=NS+'publication09/output_ROOT_READY/18720/ch4_s3_luoyang_market/payload.bin',sha256='f0cb7a2298922d7286b7eb1b6e6709d1b56a0d74a5fe90bc93d052c48f49dd62'),author=dict(path='res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json',sha256='de1911cceb5fb10e6b3b1aba1fa6d9d34057358841febdd285d25a1a1eb65e95'),old_runtime=dict(path='res://build/luoyang_city_revision_20261024e_source01/runtime_ready03/market_block_session_READY.gd',sha256='d29602487f69e0dd5a82dcdb2bf76fb9928f64319e0bae0c0d06cc806f4775ea'),output_prefix=NS+'gate_texture_repair01/market_portal_payload_ROOT_READY/output/')
raw=(json.dumps(spec,ensure_ascii=False,indent=2)+'\n').encode();dest=P/'input_ROOT_READY.json';assert not dest.exists()
with dest.open('xb')as f:f.write(raw)
key=P/'rebuild_payload_ROOT_READY.gd';before=key.read_bytes();assert before.count(b'PENDING_FROZEN_INPUT_SHA')==1;after=before.replace(b'PENDING_FROZEN_INPUT_SHA',sha(raw).encode());ready=P/'rebuild_payload_pinned_ROOT_READY.gd';assert not ready.exists()
with ready.open('xb')as f:f.write(after)
print(json.dumps(dict(project=str(P.resolve()),project_sha256=sha((P/'project.godot').read_bytes()),key=str(ready.resolve()),key_sha256=sha(after),input_sha256=sha(raw),engine_calls=0)))
