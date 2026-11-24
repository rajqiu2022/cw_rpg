"""Read-only regression: production builder in memory; never rewrite adopted art/mask."""
from pathlib import Path
import sys
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts'))
import build_world_map_v8_navigation as production

background, built = production.build()
report = production.validate(built)
assert report['surface_coverage']['covered'] == 559, report
assert report['surface_coverage']['samples'] == 559, report
assert report['centerline_foot_clearance_samples'] == 6095, report
assert report['portal_count'] == 13 and report['all_portals_connected'], report
assert report['foot_clearance_px'] == 5, report
assert np.array_equal(np.asarray(built), np.asarray(Image.open(production.MASK).convert('L'))), 'adopted mask differs from builder'
assert production.WALKABLE['village_lane'] == (490, 741)
for witness in ['reported_luoyang_bridge_wide', 'reported_snow_upper_wide', 'reported_snow_lower_wide', 'reported_village_northwest_wide']:
    assert witness in report['surface_coverage']['sections'], witness
assert len(production.BLOCKED) >= 12, 'retain negative cliff/water/roof witnesses'
print('[PublicRoadSurface] checks=12 failed=0 production_report=', report)
