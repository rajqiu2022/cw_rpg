"""No catalog/image writes: exercise validation and both real card renderers."""
import contextlib
import io
import json
import shutil
import subprocess
import unittest

import build_arsenal_catalog as catalog


class MissingPreviewTest(unittest.TestCase):
    def rows(self):
        base = dict(type="skill", name="测试招式", category="剑", group="剑法", passive=False,
                    heartArt=False, effectPreviewExists=False, qualityLevel=1, quality="绿色",
                    iconExists=False, icon="", seal="武", stats=[], price=None, acquisition=[],
                    description="说明", source="test.tres", effectName="剑光", motionLabel="释放",
                    effectPreview="assets/skill-vfx/test.webp")
        return [dict(base, id="missing"), dict(base, id="passive", passive=True),
                dict(base, id="heart", heartArt=True), dict(base, id="present", effectPreviewExists=True)]

    def test_strict_default_rejects_only_actual_missing(self):
        with self.assertRaisesRegex(ValueError, r"previews: missing$"):
            catalog.validate_skill_previews(self.rows())

    def test_diagnostic_and_both_renderers(self):
        rows = self.rows()
        warning = io.StringIO()
        with contextlib.redirect_stderr(warning):
            catalog.validate_skill_previews(rows, allow_missing_previews=True)
        self.assertIn("WARNING: active skills missing VFX previews: missing", warning.getvalue())
        self.assertEqual([row["effectPreviewMissing"] for row in rows], [True, False, False, False])
        # The JSON used by the page retains the explicit missing boolean.
        rows = json.loads(json.dumps(rows))
        notice = "特效待补 · 尚无动态预览"
        static = [catalog.render_static_card(row, 0) for row in rows]
        self.assertEqual([notice in card for card in static], [True, False, False, False])
        self.assertNotIn("skill-vfx-preview", static[0])
        self.assertIn("skill-vfx-preview", static[3])
        # Run the actual template's card() in Node; no browser/output files needed.
        template = catalog.TEMPLATE.read_text(encoding="utf-8")
        card_js = template.split("    function card(item, index) {", 1)[1].split("    function render() {", 1)[0]
        source = "const qualityColors=['green'];const esc=v=>String(v);function card(item,index){" + card_js
        source += "\nprocess.stdout.write(JSON.stringify(" + json.dumps(rows) + ".map(card)));"
        node = shutil.which("node")
        self.assertIsNotNone(node, "Node is required to verify the dynamic template")
        rendered = subprocess.run([node, "-"], input=source, encoding="utf-8", capture_output=True, check=True)
        dynamic = json.loads(rendered.stdout)
        self.assertEqual([notice in card for card in dynamic], [True, False, False, False])
        self.assertNotIn("skill-vfx-preview", dynamic[0])
        self.assertIn("skill-vfx-preview", dynamic[3])

    def test_complete_and_exempt_rows_remain_strictly_valid(self):
        rows = self.rows()[1:]
        catalog.validate_skill_previews(rows)
        self.assertFalse(any(row["effectPreviewMissing"] for row in rows))


if __name__ == "__main__":
    unittest.main()
