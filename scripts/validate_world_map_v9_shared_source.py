"""Validate that the adopted v9 map art and navigation share one route source."""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation

import build_world_map_v9_assets as builder


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "assets/processed/scene/world_map_v9/navigation_validation.json"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    adopted_mask = Image.open(builder.MASK_OUT).convert("L")
    rebuilt_mask = builder.build_mask(builder.LOGICAL_SIZE)
    require(np.array_equal(np.asarray(adopted_mask), np.asarray(rebuilt_mask)), "adopted mask drifted from route source")

    mobile_source = Image.open(builder.MOBILE_SOURCE).convert("RGB")
    adopted_mobile = Image.open(builder.MOBILE_OUT).convert("RGB")
    rebuilt_mobile = builder.enhance_roads(mobile_source, rebuilt_mask)
    require(np.array_equal(np.asarray(adopted_mobile), np.asarray(rebuilt_mobile)), "mobile background drifted from route source")

    desktop_source = Image.open(builder.DESKTOP_SOURCE).convert("RGB")
    adopted_desktop = Image.open(builder.DESKTOP_OUT).convert("RGB")
    rebuilt_desktop = builder.enhance_roads(desktop_source, builder.build_mask(desktop_source.size))
    require(np.array_equal(np.asarray(adopted_desktop), np.asarray(rebuilt_desktop)), "desktop background drifted from route source")

    report = json.loads(REPORT.read_text(encoding="utf-8"))
    runtime_report = builder.validate(rebuilt_mask)
    require(report["route_source_sha256"] == builder.source_hash(), "recorded route source hash is stale")
    require(report["mask_sha256"] == builder.sha256(builder.MASK_OUT), "recorded mask hash is stale")
    require(report["mobile_background_sha256"] == builder.sha256(builder.MOBILE_OUT), "recorded mobile background hash is stale")
    require(report["desktop_background_sha256"] == builder.sha256(builder.DESKTOP_OUT), "recorded desktop background hash is stale")
    require(report["all_portals_connected"] and report["portal_count"] == 13, "all 13 portals must share one safe component")
    require(report["foot_clearance_px"] == 5, "runtime foot clearance contract changed")
    require(report["registered_surface_samples"] == report["registered_surface_covered"], "a registered visible-road section has a gap")
    require(runtime_report["centerline_foot_clearance_samples"] == report["centerline_foot_clearance_samples"], "centreline validation drifted")

    diff = np.any(np.asarray(adopted_mobile) != np.asarray(mobile_source), axis=2)
    road_band = np.asarray(rebuilt_mask) > 0
    allowed = binary_dilation(road_band, iterations=12)
    require(np.count_nonzero(diff) > 0, "v9 road visual layer is empty")
    require(not np.any(diff & ~allowed), "v9 visual treatment changed terrain outside the shared route band")

    print(
        "[WorldMapV9SharedSource] routes=%d portals=%d clearance=%d changed_pixels=%d source=%s"
        % (
            report["route_count"],
            report["portal_count"],
            report["foot_clearance_px"],
            int(np.count_nonzero(diff)),
            report["route_source_sha256"][:12],
        )
    )


if __name__ == "__main__":
    main()
