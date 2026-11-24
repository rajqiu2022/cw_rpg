"""Pure stdin/stdout byte inverse constructor. No filesystem/network writes."""
import base64
import difflib
import hashlib
import json
import sys


def digest(data):
    return hashlib.sha256(data).hexdigest()


def build(row):
    old = base64.b64decode(row["old_base64"], validate=True)
    new = base64.b64decode(row["new_base64"], validate=True)
    if digest(old) != row["old_sha256"] or digest(new) != row["new_sha256"] or old == new:
        raise ValueError("EXACT_NONIDENTICAL_OLD_NEW_BYTES")
    left, right = old.decode("utf-8"), new.decode("utf-8")
    matcher = difflib.SequenceMatcher(None, left.splitlines(True), right.splitlines(True), autojunk=False)
    before, after = left.splitlines(True), right.splitlines(True)
    replacements = []
    for context in (3, 6, 12, 24, 48, 96, 192, 384, max(len(before), len(after))):
        replacements = []
        for group in matcher.get_grouped_opcodes(context):
            old_chunk = "".join(before[group[0][1]:group[-1][2]])
            new_chunk = "".join(after[group[0][3]:group[-1][4]])
            if not new_chunk or right.count(new_chunk) != 1:
                break
            replacements.append({"old": old_chunk, "new": new_chunk})
        else:
            break
    inverse = right
    for replacement in reversed(replacements):
        if inverse.count(replacement["new"]) != 1:
            raise ValueError("UNIQUE_NEW_HUNK")
        inverse = inverse.replace(replacement["new"], replacement["old"])
    if inverse.encode("utf-8") != old:
        raise ValueError("WHOLE_BYTE_INVERSE")
    result = {"path": row["path"], "old_sha256": row["old_sha256"], "new_sha256": row["new_sha256"],
              "old_snapshot": row["old_snapshot"], "new_snapshot": row["new_snapshot"],
              "whole_inverse": True, "replacements": list(reversed(replacements))}
    navigation = row.get("navigation_source")
    if navigation is not None:
        if not navigation or left.count(navigation) != 1 or right.count(navigation) != 1:
            raise ValueError("NAVIGATION_FUNCTION_COMPLETE_UNCHANGED")
        result["navigation_source"] = navigation
    return result


if __name__ == "__main__":
    request = json.load(sys.stdin)
    json.dump(build(request), sys.stdout, ensure_ascii=True, separators=(",", ":"), allow_nan=False)
