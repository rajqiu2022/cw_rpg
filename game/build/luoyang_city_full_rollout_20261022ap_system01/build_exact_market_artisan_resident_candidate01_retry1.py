"""Original Router contains both EOL styles; preserve each matched hunk style."""
from pathlib import Path
path=Path(__file__).with_name("build_exact_market_artisan_resident_candidate01.py")
code=path.read_text(encoding="utf-8")
old='OUT=ROOT/"exact_market_artisan_resident_candidate01"'
assert code.count(old)==1
code=code.replace(old,'OUT=ROOT/"exact_market_artisan_resident_candidate01_retry1"')
old=' old=old.replace("\\n",eol).encode();new=new.replace("\\n",eol).encode()\n assert b.count(old)==1,old[:140]'
new=''' old_text,new_text=old,new
 old=old_text.replace("\\n",eol).encode()
 if b.count(old)!=1:
  eol="\\n" if eol=="\\r\\n" else "\\r\\n"
  old=old_text.replace("\\n",eol).encode()
 new=new_text.replace("\\n",eol).encode()
 assert b.count(old)==1,old[:140]'''
assert code.count(old)==1
code=code.replace(old,new)
exec(compile(code,str(path),"exec"),{"__file__":str(path),"__name__":"__main__"})
