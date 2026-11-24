"""Mechanical NEW-only stage and full-text inverse; never writes canonical sources."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[2]
SOURCE = REPO / "game/scripts/field/field_walkable_controller.gd"
EXPECTED = "93c4d7a7b2fef829f8f7e1c88c9dd00b17795f4794e167682a59ae1f52ee22e0"
DEST = ROOT / "stage_CANDIDATE"

def sha(data):
    return hashlib.sha256(data).hexdigest()

def main():
    before = SOURCE.read_bytes()
    assert sha(before) == EXPECTED, "canonical Field changed; do not rebase silently"
    patch = (ROOT / "Field_changes_CANDIDATE.patch").read_text(encoding="utf-8")
    # apply_patch's context hunks, without line-number dependence. Full-text
    # replace is unique per hunk; all inverse replacements verified in reverse.
    chunks = patch.split("\n@@\n")[1:]
    text = before.decode("utf-8")
    original = text
    inverses = []
    for chunk in chunks:
        lines = chunk.splitlines()
        lines = [line for line in lines if not line.startswith("*** End Patch")]
        old = "\n".join(line[1:] for line in lines if line.startswith((" ", "-")))
        new = "\n".join(line[1:] for line in lines if line.startswith((" ", "+")))
        normalized = text.replace("\r\n", "\n")
        assert old and normalized.count(old) == 1, f"hunk not unique: {old[:120]}"
        # Map normalized search bounds back to exact current source bytes;
        # preserve every byte outside the explicitly covered hunk.
        start = normalized.index(old)
        end = start + len(old)
        bounds = []
        cursor = 0
        for char in text:
            if char != "\r":
                bounds.append(cursor)
            cursor += 1
        bounds.append(len(text))
        raw_start, raw_end = bounds[start], bounds[end]
        exact_old = text[raw_start:raw_end]
        text = text[:raw_start] + new + text[raw_end:]
        inverses.append((new, exact_old))
    restored = text
    for new, old in reversed(inverses):
        assert restored.count(new) == 1
        restored = restored.replace(new, old, 1)
    assert restored.encode("utf-8") == before
    assert not DEST.exists(), "preserve previous stage"
    DEST.mkdir()
    candidate = text.encode("utf-8")
    (DEST / "Field_CANDIDATE.gd").write_bytes(candidate)
    (DEST / "Field_before_EXACT.gd.source").write_bytes(before)
    receipt = {
        "status": "STATIC_ONLY_NOT_PARSED_NOT_ENGINE_RUN_NOT_DEPLOYED",
        "source": str(SOURCE), "source_sha256": sha(before),
        "candidate_sha256": sha(candidate), "hunks": len(chunks),
        "line_endings": "only explicit hunk spans use LF; all outside bytes preserved",
        "full_byte_inverse": True,
        "original_exact_bytes_backed_up": True,
        "formal_source_current_unchanged": SOURCE.read_bytes() == before,
        "helper_sha256": sha((ROOT / "npc_conversation_CANDIDATE.gd").read_bytes()),
        "patch_sha256": sha((ROOT / "Field_changes_CANDIDATE.patch").read_bytes()),
    }
    (DEST / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2))

if __name__ == "__main__":
    main()
