from __future__ import annotations

import argparse
from pathlib import Path


SOURCE_VIEWPORT = "var _emscripten_glViewport=(x0,x1,x2,x3)=>GLctx.viewport(x0,x1,x2,x3);"
SAFE_VIEWPORT = "var _emscripten_glViewport=(x0,x1,x2,x3)=>{GLctx.viewport(x0,x1,x2,x3)};"
COMPAT_SOURCE_VIEWPORT = "var _glViewport=(x0,x1,x2,x3)=>GLctx.viewport(x0,x1,x2,x3);"
COMPAT_SAFE_VIEWPORT = "var _glViewport=(x0,x1,x2,x3)=>{GLctx.viewport(x0,x1,x2,x3)};"
GODOT_FACTORY_MARKERS = ("var Godot=(()=>{", "var Godot = (() => {")
FS_END_MARKER = "};var SYSCALLS={"
FS_EXPOSURE = r'''};Module["FS"]=FS;var SYSCALLS={'''
GODOT_BOOTSTRAP = """
if(typeof Module!=="undefined"){
Godot(Module).then(function(runtimeModule){readyPromiseResolve(runtimeModule)}).catch(function(error){readyPromiseReject(error)});
}
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Normalize Godot Emscripten JS before WeChat conversion.")
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    if source == output:
        raise SystemExit("Source and output must be different; keep the canonical Web export unchanged.")
    text = source.read_text(encoding="utf-8")
    viewport_rewrites = (
        (SOURCE_VIEWPORT, SAFE_VIEWPORT),
        (COMPAT_SOURCE_VIEWPORT, COMPAT_SAFE_VIEWPORT),
    )
    matched_viewports = [(source_text, safe_text) for source_text, safe_text in viewport_rewrites if text.count(source_text) == 1]
    if len(matched_viewports) != 1:
        raise SystemExit(
            "Expected exactly one supported Godot glViewport concise-arrow function, "
            f"found {len(matched_viewports)}. The upstream Web template may have changed."
        )
    source_viewport, safe_viewport = matched_viewports[0]
    normalized = text.replace(source_viewport, safe_viewport, 1)
    if sum(normalized.count(marker) for marker in GODOT_FACTORY_MARKERS) != 1:
        raise SystemExit("Expected exactly one Godot factory marker.")
    if normalized.count(FS_END_MARKER) != 1:
        raise SystemExit("Expected exactly one Godot FS boundary marker.")
    normalized = normalized.replace(FS_END_MARKER, FS_EXPOSURE, 1)
    normalized += GODOT_BOOTSTRAP
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(normalized, encoding="utf-8")
    print(f"Prepared WeChat-safe framework source: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
