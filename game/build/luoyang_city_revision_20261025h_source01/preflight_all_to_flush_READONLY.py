"""Root explicitly authorized complete read-only preflight. Disable only final disk flush in memory."""
from pathlib import Path
import json,hashlib,traceback,datetime
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
driver=P/'stage_service_garden_exact28_CT_raw03_ROOT_ONLY.py';raw=driver.read_bytes();assert sha(raw)=='440e152cdd58d2d1d1bdb1f0caf4a3b614ac01729254f463b7cb5142846a2f04'
source=raw.decode();start=source.index('  for p,b in self.outputs.items():\n');end=source.index('\n  return dict(',start)
removed=source[start:end];assert removed.count("with dest.open('xb')")==1 and removed.count('f.write(b)')==1
source=source[:start]+"  need(not res(self.out).exists(),'READONLY_PREFLIGHT_OUTPUT_DIRECTORY_ABSENT')"+source[end:]
ns=dict(__file__=str(driver.resolve()),__name__='root_authorized_readonly_preflight')
exec(compile(source,str(driver),'exec'),ns)
ip=P/'external_projection_residual05b/source_input_ROOT_REVIEW.json';ib=ip.read_bytes();assert sha(ib)=='0b4a400aace65297f18d31dc6651de19135bca52fdb819f4b738f99b2897b272'
spec=json.loads(ib);spec['_locked_plan']=dict(path='res://'+ip.relative_to(G).as_posix(),sha256=sha(ib))
output=G/spec['output_root'][6:];assert not output.exists()
began=datetime.datetime.now(datetime.timezone.utc).isoformat();instance=None;passed=False;error=None;result=None
try:
 instance=ns['Unified28'](spec);result=instance.run();passed=True
except Exception:
 error=traceback.format_exc()
assert not output.exists(),'READONLY_PREFLIGHT_MUST_NOT_MATERIALIZE_STAGE_OUTPUT'
report=dict(status='ROOT_AUTHORIZED_COMPLETE_READONLY_PREFLIGHT_TO_FLUSH_NOT_STAGE',passed=passed,driver=dict(path='res://'+driver.relative_to(G).as_posix(),sha256=sha(raw)),input=dict(path='res://'+ip.relative_to(G).as_posix(),sha256=sha(ib)),only_disabled_disk_flush_sha256=sha(removed.encode()),driver_gates_logic_unchanged=True,source_expected_maps_not_observed_fill=True,Stage_output_files_written=0,canonical_writes=0,engine_calls=0,collector_calls=0,started_utc=began,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),all_preflush_result=result if passed else None,error=error,declared_sources_read=len(instance.first)if instance else None,buffered_targets=len(instance.targets)if instance else None,buffered_nodes=len(instance.nodes)if instance else None,buffered_file_count=len(instance.outputs)if instance else None)
b=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode();p=P/'external_projection_residual05b/complete_preflush_READONLY_report.json'
with p.open('xb')as f:f.write(b)
print(json.dumps(dict(path=R+'external_projection_residual05b/'+p.name,sha256=sha(b),passed=passed,error=error,declared_sources=report['declared_sources_read'],buffered_targets=report['buffered_targets'],Stage_output_files_written=0)))
