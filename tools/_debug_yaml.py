import yaml

doc = yaml.safe_load(open("prompts/tasks.yaml", encoding="utf-8"))
tasks = doc["tasks"]

for i, t in enumerate(tasks):
    tid = t.get("id", "")
    tpl = t.get("template", "")
    if "quest_panel" in str(tid) or "quest_panel" in str(tpl):
        print(f"  [{i}] id={tid} tpl={tpl}")

# Also check the specific task
for t in tasks:
    if t.get("id") == "ui_quest_panel_kit_v2":
        print(f"\nv2 task template: {t.get('template')}")
