"""NEW pure old-pointer/reference audit for fixed03, no stager import."""
from prepare_handoff10 import HERE
text = (HERE / "read_unified_finish_input02_static.py").read_bytes().decode("utf-8")
text = text.replace("unified_finish_input02_ROOT_LOCKED.json", "unified06_input03_ROOT_LOCKED.json")
text = text.replace("37210069e96cb9f867cb902d00073a96ea5865bb44398ec798c7200e23a5a9ba", "0b4f5447f870133b23f18376c06bb0778893adc1f16dd6475a9431031ed8bfd1")
exec(compile(text, str(HERE / "read_unified_finish_input02_static.py") + "#fixed03", "exec"))
