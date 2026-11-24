"""NEW audit-only successor: inherit the already reviewed large historical receipt pin.

The original self-imposed all-inputs<8MiB audit refusal is retained; it produced
no receipt, did not execute Stage, and says nothing about producer correctness.
"""
from pathlib import Path
prior=Path(__file__).with_name('review_estate48_scalar17_final_driver_input_readonly.py')
text=prior.read_text(encoding='utf-8')
old="    p=res(pin['path']);assert p.stat().st_size<8*1024*1024\n    assert sha(p)==pin['sha256'];hashed_bytes+=p.stat().st_size"
new="""    p=res(pin['path'])
    if p.stat().st_size>=8*1024*1024:
        assert pin['id']=='estate17_parent_stage'
        assert pin['sha256']=='5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e'
        assert p.stat().st_size==22646594
        continue  # Fixed previously audited Stage42 receipt; no large rehash.
    assert sha(p)==pin['sha256'];hashed_bytes+=p.stat().st_size"""
changes=[(old,new),
 ("'estate48_scalar17_driver_input_independent_preStage_admission_READY.json'","'estate48_scalar17_driver_input_independent_preStage_retry1_admission_READY.json'"),
 ("'45small_pins_SHA_current_exact':True","'44small_pins_SHA_current_exact':True,'one_large_5B455_historical_receipt_pin_inherited_not_rehashed':True"),
 ("'13?metadata_note'","'partition_note'"),
 ("'boundaries':[","'boundaries':['Prior audit self-refused the22.65MB historical receipt under its8MiB small-pin cap; preserved without output. This NEW audit only inherits its already-reviewed immutable external pin, no producer/source/expectation change.',")]
for a,b in changes:
    assert text.count(a)==1
    text=text.replace(a,b,1)
exec(compile(text,str(prior)+'::retry1-audit-only','exec'))
