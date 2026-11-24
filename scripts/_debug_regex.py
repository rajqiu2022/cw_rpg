import re
p = r'F:\Code\RPG_GAME\game\data\dialogs\ch1_tutorial_xingfantian.tres'
c = open(p, encoding='utf-8').read()
m = re.findall(r'speaker\s*=\s*"([^"]*)"', c)
print('speakers found:', len(m), m[:3])
t = re.findall(r'text\s*=\s*"([^"]*)"', c)
print('texts found:', len(t))
if t: print('first:', t[0][:80])
