"""Root-only NEW metadata compiler; no Godot, collector, import or canonical write.

Expected values come from pinned historical maps, explicit source groups and
the byte-exact executable authority graph, never from a current-disk crawl.
All generated files are buffered until every preflight/inverse check succeeds.
"""
from __future__ import annotations

import argparse
import base64
import copy
import difflib
import hashlib
import json
import re
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[2]
PREFIX = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
AUTHORITY_SHA = "621343ea4bc1486dcd0ff16405d92ed0ec08747d10a5c503f4cd5e2507db30fd"
AUTHORITY_TARGET = "res://scripts/city/luoyang_execution_authority_20261022ap.gd"
OWNED = {
    "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd",
    "res://scripts/city/luoyang_assembled_interiors_20261016g.gd",
    "res://scripts/city/luoyang_estate_family_20261021am.gd",
    "res://scripts/autoload/scene_router.gd",
    "res://scripts/city/luoyang_harbour_life_runtime_20261016.gd",
    "res://scripts/city/luoyang_district_life_20261016f.gd",
    "res://scripts/city/luoyang_docks_workyard_20261019ac.gd",
    "res://scripts/city/luoyang_city_tasks_20261016.gd",
    "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd",
    "res://scripts/field/field_walkable_controller.gd",
    "res://scripts/city/luoyang_temple_assembly_20261016.gd",
}
EXTERNAL = {
    "res://scripts/city/luoyang_full_city_index_20261022ap.gd",
    "res://scripts/city/luoyang_environment_index_20261022ap.gd",
    "res://scripts/city/luoyang_execution_index_20261022ap.gd",
    "res://scripts/city/luoyang_quarters_index_20261022ap.gd",
}
BASE_ROOT = "res://build/luoyang_market_two_shops_20261021ao_system01/staged_dependency_retry3/maps/"
BASELINES = {
    "ch4_s0_luoyang_gate": ("8e367a15896c6ff807bf2cbd97e35862831678b33b733a82d282088a7bafa21d", 720),
    "ch4_s1_luoyang_yamen": ("2cf0027a0dd512dcc10e83c57aac67eed8111667bee9b80d11ddf240ac371027", 1063),
    "ch4_s2_canal_docks": ("dc827ce36b513d982e15b6177100094db2b0e48bb43af91e4771cc43b8461f92", 1544),
    "ch4_s3_luoyang_market": ("545ccccce8ec56570d0882d3f8ad49f5adc0095539abe127012ab28ca15bd12d", 1367),
}
REQUIRED_GATES = {"garden_background_permission", "garden_native_publication", "market_native_publication", "artisan_native_publication", "root_target_preauthorization"}
HISTORICAL_EDGES = {
    "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd": [(
        "1c5ba0b369ae28ce532a3e697f1411e1b734cba5e3f96d58d8e5c74ea3e75e35",
        "527d77ef3c8fddd0277f3d8e5e7a0cde475edded02ca3388aff767676f9687a1",
        "res://build/luoyang_market_two_shops_20261021ao_root01/integration1/predeploy_backup/scripts/city/luoyang_precomputed_bundle_20261018r.gd",
        "res://build/luoyang_market_two_shops_20261021ao_system01/B_fade_successor_READY.gd",
    )],
    "res://scripts/city/luoyang_district_life_20261016f.gd": [
        ("bcd4e401303e97cd65075c86c9bba6d08c4b3d542a36a1ec546f73c949670118", "1b44e7452f7fac5056c6da65af1560d0dafdb2ad61d0020291ad2a17a7842fa9", "res://build/luoyang_docks_district08_20261019aa_source01/before/District_original.gd", "res://build/luoyang_market_two_shops_20261021ao_system01/District_READY.gd"),
        ("0137393f3715558887f0c69598c4346e5a2e9cd9b1b9c1091f85ea12a0f6afea", "1b44e7452f7fac5056c6da65af1560d0dafdb2ad61d0020291ad2a17a7842fa9", "res://build/luoyang_shore_market_20261020ae_root01/predeploy_backup/scripts/city/luoyang_district_life_20261016f.gd", "res://build/luoyang_market_two_shops_20261021ao_system01/District_READY.gd"),
        ("c4fb86ebd6d7683a9a7ddc96c6f72f98fe614fc8c6d4ac18424bfe3ebf09d351", "1b44e7452f7fac5056c6da65af1560d0dafdb2ad61d0020291ad2a17a7842fa9", "res://build/luoyang_market_two_shops_20261021ao_system01/before/District_C4FB.gd", "res://build/luoyang_market_two_shops_20261021ao_system01/District_READY.gd"),
    ],
}


def need(ok, why):
    if not ok:
        raise ValueError(why)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def valid_sha(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def res(path):
    need(isinstance(path, str) and path.startswith("res://") and "\\" not in path, "RESOURCE_DOMAIN")
    parts = PurePosixPath(path[6:]).parts
    need(parts and all(p not in (".", "..") for p in parts), "RESOURCE_TRAVERSAL")
    result = ROOT.joinpath(*parts).resolve()
    need(result.is_relative_to(ROOT), "WORKSPACE_ESCAPE")
    return result


def encode(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + "\n").encode("utf-8")


def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def pointer(value, keys):
    for key in keys:
        value = value[key]
    return value



def patch_chunks(body):
    """Read emitted literal-EOL hunks, not the source matcher opcodes."""
    chunks, left, right = [], [], []
    for line in body.splitlines(keepends=True):
        if line == "@@\n":
            if left or right:
                chunks.append(("".join(left), "".join(right)))
            left, right = [], []
            continue
        need(line and line[0] in " +-", "PATCH_LITERAL_LINE_PREFIX")
        if line[0] in " -":
            left.append(line[1:])
        if line[0] in " +":
            right.append(line[1:])
    if left or right:
        chunks.append(("".join(left), "".join(right)))
    return chunks


def replay_chunks(text, chunks):
    cursor, output = 0, []
    for old, new in chunks:
        found = text.find(old, cursor)
        need(found >= 0, "PATCH_EMITTED_CONTEXT_NOT_FOUND")
        output.extend((text[cursor:found], new))
        cursor = found + len(old)
    output.append(text[cursor:])
    return "".join(output)


def build_file_patch(target, before, after):
    """Candidates are literal UTF8/LF with final LF; never normalize input.
    Old files may contain literal CRLF/mixed EOL; removed/context payload keeps
    those bytes. A CRLF or no-final-LF candidate fails closed instead of being
    silently rewritten to an unrepresentable apply_patch payload.
    """
    need(after and after.endswith(b"\n") and b"\r" not in after and not after.startswith(b"\xef\xbb\xbf"), "PATCH_CANDIDATE_REQUIRES_UTF8_LF_FINAL_LF_NO_BOM_NO_NORMALIZATION")
    new = after.decode("utf-8")
    trailing = len(after) - len(after.rstrip(b"\n"))
    if before is None:
        body = "".join("+" + line for line in new.splitlines(keepends=True))
        replayed = "".join(line[1:] for line in body.splitlines(keepends=True)).encode("utf-8")
        need(replayed == after, "ADD_FILE_EMITTED_PAYLOAD_BYTE_RECONSTRUCTION")
        return "*** Add File: " + target + "\n" + body, {
            "kind": "AddFile", "candidate_sha256": digest(after),
            "reconstructed_sha256": digest(replayed), "forward_exact_bytes": True,
            "trailing_lf_bytes_preserved": trailing, "candidate_eol": "LF",
        }
    need(not before or before.endswith(b"\n"), "PATCH_OLD_NO_FINAL_LF_DOMAIN_NOT_SUPPORTED_NO_NORMALIZATION")
    old = before.decode("utf-8")
    need(old != new, "NO_NOOP_DEPLOYMENT_TARGET")
    left, right = old.splitlines(keepends=True), new.splitlines(keepends=True)
    matcher = difflib.SequenceMatcher(None, left, right, autojunk=False)
    for context in (3, 6, 12, 24, 48, 96, 192, 384, max(len(left), len(right))):
        body = []
        for group in matcher.get_grouped_opcodes(context):
            body.append("@@\n")
            for tag, a, b, c, d in group:
                if tag == "equal":
                    body.extend(" " + line for line in left[a:b])
                else:
                    if tag in ("delete", "replace"):
                        body.extend("-" + line for line in left[a:b])
                    if tag in ("insert", "replace"):
                        body.extend("+" + line for line in right[c:d])
        serialized = "".join(body)
        chunks = patch_chunks(serialized)
        try:
            replayed = replay_chunks(old, chunks).encode("utf-8")
            inverse = replay_chunks(new, [(b, a) for a, b in chunks]).encode("utf-8")
        except ValueError:
            continue
        if replayed == after and inverse == before:
            return "*** Update File: " + target + "\n" + serialized, {
                "kind": "UpdateFile", "candidate_sha256": digest(after),
                "reconstructed_sha256": digest(replayed), "forward_exact_bytes": True,
                "whole_inverse_exact_bytes": True, "hunks": len(chunks),
                "literal_context_lines": context, "old_crlf_count": before.count(b"\r\n"),
                "old_lf_count": before.count(b"\n"), "candidate_eol": "LF",
                "trailing_lf_bytes_preserved": trailing,
            }
    raise ValueError("EMITTED_PATCH_CANNOT_RECONSTRUCT_EXACT_BYTES")


class Stage:
    def __init__(self, spec):
        self.spec = spec
        self.inputs = {}
        self.input_bytes = {}
        self.first = {}
        plan_pin = spec.get("_locked_plan")
        if plan_pin:
            self.read(plan_pin["path"], plan_pin["sha256"])
        self.nodes = {}
        self.outputs = {}
        self.targets = {}
        self.proofs = {}
        self.groups = {r["id"]: r for r in spec.get("source_groups", [])}
        self.group_stack = set()
        self.prospective = {r["target"]: r for r in spec.get("prospective_targets", [])}
        need(len(self.prospective) == len(spec.get("prospective_targets", [])), "DUPLICATE_PROSPECTIVE_TARGET")
        self.out = spec.get("output_root", "")
        need(self.out.startswith(PREFIX + "outputs/") and self.out.endswith("/"), "NEW_FINALIZE_OUTPUT_ONLY")
        need(not res(self.out).exists(), "OUTPUT_MUST_NOT_EXIST")
        for row in spec.get("pinned_inputs", []):
            need(row["id"] not in self.inputs, "DUPLICATE_INPUT_ID")
            data = self.read(row["path"], row["sha256"])
            self.input_bytes[row["id"]] = data
            self.inputs[row["id"]] = row
        self.authority = self.read_json_input(spec["authority_input"])
        helper = self.inputs[spec["authority_helper_input"]]
        need(helper["sha256"] == AUTHORITY_SHA, "FROZEN_AUTHORITY_621343_REQUIRED")
        need(self.authority.get("status") == "ROOT_APPROVED_AP_EXACT_EXECUTABLE_SUCCESSION", "EXECUTION_APPROVAL_NOT_READY")
        need(self.authority.get("source_sha256", {}).get(AUTHORITY_TARGET) == AUTHORITY_SHA, "AUTHORITY_HELPER_LEAF")
        self.validate_authority()

    def read(self, path, expected):
        need(valid_sha(expected), "EXPLICIT_SHA_REQUIRED:" + str(path))
        data = res(path).read_bytes()
        need(digest(data) == expected, "PIN_CHANGED:" + path)
        self.first[path] = expected
        return data

    def read_json_input(self, ident):
        need(ident in self.input_bytes, "UNPINNED_INPUT:" + ident)
        return json.loads(self.input_bytes[ident])

    def validate_authority(self):
        owned = self.authority.get("owned", {})
        need(isinstance(owned, dict) and set(owned) == OWNED - {"res://scripts/city/luoyang_estate_family_20261021am.gd"}, "EXACT_TEN_CHANGED_CODES_CLOSED_ELEVEN_DOMAIN")
        pins = self.authority["source_sha256"]
        for path, row in owned.items():
            need(valid_sha(row.get("current_sha256")) and isinstance(row.get("edges"), list) and row["edges"], "OWNED_ROW:" + path)
            for edge in row["edges"]:
                need(edge.get("path") == path and edge.get("whole_inverse") is True, "EDGE_IDENTITY")
                oldp, newp = edge["old_snapshot"], edge["new_snapshot"]
                need(oldp != path and (newp == path or newp.startswith("res://build/luoyang_")), "SNAPSHOT_DOMAIN")
                need(pins.get(oldp) == edge["old_sha256"] and (newp == path or pins.get(newp) == edge["new_sha256"]), "SNAPSHOT_NOT_PINNED")
                before = self.read(oldp, edge["old_sha256"])
                after = self.read(newp, edge["new_sha256"])
                text = after.decode("utf-8")
                replacements = edge.get("replacements")
                need(isinstance(replacements, list) and replacements, "EXPLICIT_HUNKS_REQUIRED")
                for hunk in replacements:
                    need(set(hunk) == {"old", "new"} and hunk["old"] != hunk["new"] and hunk["new"] and text.count(hunk["new"]) == 1, "EXACT_ONE_NEW_HUNK")
                    text = text.replace(hunk["new"], hunk["old"])
                need(text.encode("utf-8") == before, "WHOLE_BYTE_EXECUTION_INVERSE:" + path)
                if "navigation_source" in edge:
                    nav = edge["navigation_source"]
                    need(isinstance(nav, str) and nav and before.decode("utf-8").count(nav) == after.decode("utf-8").count(nav) == 1, "UNCHANGED_WHOLE_NAVIGATION")
            current = row["current_sha256"]
            need(any(e["new_sha256"] == current for e in row["edges"]), "CURRENT_CODE_WITHOUT_EXACT_EDGE")
            candidates = {(e["new_snapshot"], e["new_sha256"]) for e in row["edges"] if e["new_sha256"] == current}
            need(len(candidates) == 1, "UNIQUE_CURRENT_OWNED_PROSPECTIVE_SNAPSHOT")
            candidate, expected = next(iter(candidates))
            if path in self.prospective:
                need(self.prospective[path]["candidate_path"] == candidate and self.prospective[path]["sha256"] == expected, "EXPLICIT_PROSPECTIVE_DISAGREES_WITH_FROZEN_AUTHORITY")
            else:
                self.prospective[path] = {"target": path, "candidate_path": candidate, "sha256": expected}
        for path, required in HISTORICAL_EDGES.items():
            actual = {(e["old_sha256"], e["new_sha256"], e["old_snapshot"], e["new_snapshot"]) for e in owned[path]["edges"]}
            need(set(required) <= actual, "B_1C5_527_AND_D_THREE_HISTORICAL_FULL_SNAPSHOTS_REQUIRED")

    def approved(self, path, historical):
        row = self.authority.get("owned", {}).get(path)
        if row is None:
            return False
        frontier, visited = [row["current_sha256"]], set()
        for _ in range(16):
            following = []
            for sha in frontier:
                if sha == historical:
                    return True
                if sha in visited:
                    continue
                visited.add(sha)
                following.extend(e["old_sha256"] for e in row["edges"] if e["new_sha256"] == sha)
            frontier = following
        return False

    def value(self, item):
        if isinstance(item, dict) and "$sha" in item:
            node = self.nodes[item["$sha"]]
            return node["disabled_sha256"] if item.get("variant") == "disabled" else node["sha256"]
        if isinstance(item, dict) and set(item) == {"$owned"}:
            return self.authority["owned"][item["$owned"]]["current_sha256"]
        if isinstance(item, dict) and set(item) == {"$pin"}:
            return self.inputs[item["$pin"]]["sha256"]
        if isinstance(item, dict):
            return {k: self.value(v) for k, v in item.items()}
        if isinstance(item, list):
            return [self.value(v) for v in item]
        return item

    def verify_leaf(self, path, expected):
        if path in self.targets:
            need(self.targets[path]["candidate_sha256"] == expected, "STAGED_TARGET_LEAF_MISMATCH:" + path)
        elif path in self.prospective:
            row = self.prospective[path]
            need(row["sha256"] == expected, "PROSPECTIVE_EXPECTATION_MISMATCH:" + path)
            self.read(row["candidate_path"], expected)
        else:
            self.read(path, expected)

    def leaf_bytes(self, path, expected):
        self.verify_leaf(path, expected)
        if path in self.targets:
            candidate = self.targets[path]["candidate_path"]
            return self.outputs[candidate] if candidate in self.outputs else self.read(candidate, expected)
        if path in self.prospective:
            return self.read(self.prospective[path]["candidate_path"], expected)
        return self.read(path, expected)

    def media_closure(self, sources, declared_roots):
        checked = []
        for row in declared_roots:
            texture = row["path"]
            need(texture in sources and texture + ".import" in sources, "DECLARED_RUNTIME_MEDIA_AND_SIDECAR_REQUIRED")
            suffix = PurePosixPath(texture).suffix.lower()
            domain = ".sample" if suffix == ".wav" else ".ctex" if suffix in {".png", ".jpg", ".jpeg"} else None
            need(domain is not None, "UNSUPPORTED_RUNTIME_MEDIA_DOMAIN_MUST_BE_EXPLICITLY_EXTENDED")
            remap = self.leaf_bytes(texture + ".import", sources[texture + ".import"]).decode("utf-8")
            actual = set(re.findall(r'^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$', remap, re.M))
            need(actual and actual == set(row["compiled_paths"]) and all(p.endswith(domain) and p in sources for p in actual), "EXACT_DECLARED_IMAGE_CTEX_OR_WAV_SAMPLE_REMAP")
            source_files = re.findall(r'^source_file="(res://[^"\r\n]+)"\r?$', remap, re.M)
            need(source_files == [texture], "SIDECAR_SOURCE_FILE_IDENTITY")
            for compiled in actual:
                self.verify_leaf(compiled, sources[compiled])
            checked.append({"path": texture, "compiled_paths": sorted(actual), "domain": domain})
        return checked

    def promote_owned(self, source):
        output = copy.deepcopy(source)
        for path, historical in list(output.items()):
            need(valid_sha(historical), "SOURCE_MAP_SHA:" + path)
            if path in self.authority["owned"]:
                need(self.approved(path, historical), "NO_EXACT_HISTORICAL_EDGE:" + path)
                output[path] = self.authority["owned"][path]["current_sha256"]
        return output

    def group(self, ident):
        need(ident in self.groups and ident not in self.group_stack, "UNKNOWN_OR_CYCLIC_GROUP:" + ident)
        self.group_stack.add(ident)
        row = self.groups[ident]
        if row["kind"] == "explicit":
            sources = self.value(row["leaves"])
        elif row["kind"] == "input_dictionary":
            sources = copy.deepcopy(pointer(self.read_json_input(row["input"]), row["pointer"]))
        elif row["kind"] == "node_dictionary":
            sources = copy.deepcopy(pointer(self.nodes[row["node"]]["value"], row["pointer"]))
        elif row["kind"] == "union":
            sources = {}
            for child in row["groups"]:
                self.merge(sources, self.group(child))
        else:
            raise ValueError("UNKNOWN_GROUP_KIND")
        need(isinstance(sources, dict), "GROUP_MUST_BE_PATH_SHA_DICTIONARY")
        if row.get("promote_owned") is True:
            sources = self.promote_owned(sources)
        for path, sha in sources.items():
            self.verify_leaf(path, sha)
        self.group_stack.remove(ident)
        return sources

    def merge(self, into, additions):
        for path, sha in additions.items():
            if path in into and into[path] != sha:
                need(path in self.authority["owned"] and self.approved(path, into[path]) and sha == self.authority["owned"][path]["current_sha256"], "UNDECLARED_EXISTING_SOURCE_REPLACEMENT:" + path)
            into[path] = sha

    def change(self, value, operations, source_only=False):
        back = copy.deepcopy(value)
        deltas = []
        allowed = {"source_sha256", "owned_source_sha256", "legacy_source_sha256", "runtime_authority_sha256", "runtime_source_successions", "registry_sha256", "source_migration", "ap_source_successor"}
        for op in operations:
            keys = op["pointer"]
            need(isinstance(keys, list) and keys, "EXPLICIT_NONROOT_JSON_POINTER")
            if source_only:
                need(keys[0] in allowed or (keys[0] == "rooms" and len(keys) >= 3 and keys[2] == "source_sha256"), "NON_SOURCE_METADATA_CHANGE")
            holder, key = pointer(value, keys[:-1]), keys[-1]
            exists = key in holder
            need(exists == op["existed"], "JSON_OLD_EXISTENCE")
            old = copy.deepcopy(holder[key]) if exists else None
            need(not exists or same(old, op["old"]), "JSON_EXACT_OLD_VALUE")
            if op["op"] == "remove":
                need(exists, "REMOVE_MUST_EXIST")
                del holder[key]
            else:
                need(op["op"] == "set", "UNKNOWN_JSON_OPERATION")
                holder[key] = self.value(op["new"])
            deltas.append({"pointer": keys, "existed": exists, "old": old})
        restored = copy.deepcopy(value)
        for delta in reversed(deltas):
            holder, key = pointer(restored, delta["pointer"][:-1]), delta["pointer"][-1]
            if delta["existed"]:
                holder[key] = delta["old"]
            else:
                del holder[key]
        need(same(restored, back), "WHOLE_TYPED_JSON_INVERSE")
        return deltas

    def output(self, name, data):
        need(isinstance(name, str) and name and ".." not in PurePosixPath(name).parts and not name.startswith(("/", "\\")) and "\\" not in name, "OUTPUT_NAME_DOMAIN")
        path = self.out + name
        need(path not in self.outputs, "DUPLICATE_OUTPUT")
        self.outputs[path] = data
        return path, digest(data)

    def target(self, target, old, path, sha):
        need(target not in self.targets and Path(target).suffix in (".json", ".gd"), "METADATA_CODE_TARGETS_ONLY_NO_NATIVE_WRITE")
        if old == "ABSENT":
            need(not res(target).exists(), "TARGET_MUST_BE_ABSENT:" + target)
        else:
            self.read(target, old)
        self.targets[target] = {"target": target, "old_sha256": old, "candidate_path": path, "candidate_sha256": sha}

    def build_node(self, row):
        ident, kind = row["id"], row["kind"]
        need(ident not in self.nodes, "DUPLICATE_NODE_ID")
        derived_proof = None
        if "target" in row and row["old_sha256"] != "ABSENT":
            if self.inputs[row["base_input"]]["sha256"] != row["old_sha256"]:
                derived_proof = row.get("derived_parent")
                need(kind == "metadata" and isinstance(derived_proof, dict) and self.inputs[derived_proof["predecessor_input"]]["sha256"] == row["old_sha256"], "EXACT_DERIVED_METADATA_PARENT_REQUIRED")
                proof = self.read_json_input(derived_proof["proof_input"])
                need(pointer(proof, derived_proof["proof_pointer"]) is True, "ACTUAL_PUBLICATION_WHOLE_INVERSE_NOT_PASSED")
                previous = self.read_json_input(derived_proof["predecessor_input"])
                published = self.read_json_input(row["base_input"])
                need(derived_proof.get("protected_pointers"), "DECLARED_UNCHANGED_OLD_ROWS_REQUIRED")
                for keys in derived_proof["protected_pointers"]:
                    need(same(pointer(previous, keys), pointer(published, keys)), "DERIVED_PUBLICATION_CHANGED_PROTECTED_OLD_ROW")
        base = self.read_json_input(row["base_input"]) if kind != "index" else None
        if kind == "metadata":
            value = copy.deepcopy(base)
            deltas = self.change(value, row.get("operations", []), True)
            policy = row["source_policy"]
            need(policy in {"old_city_or_market", "quarter", "estate_legacy"}, "EXPLICIT_METADATA_SOURCE_POLICY")
            forbidden = set(EXTERNAL)
            if policy == "quarter":
                forbidden = {
                    "res://scripts/city/luoyang_full_city_index_20261022ap.gd",
                    "res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd",
                    "res://scripts/city/luoyang_quarters_index_20261022ap.gd",
                }
            forbidden |= set(row.get("forbidden_source_paths", []))
            forbidden.add(row.get("target"))
            need(not (row.get("source_fields") and row.get("source_bundle")), "CHOOSE_FIELDS_OR_DISJOINT_BUNDLE")
            for field in row.get("source_fields", []):
                old = copy.deepcopy(pointer(value, field["pointer"]))
                updated = self.promote_owned(old) if field.get("promote_owned") is True else copy.deepcopy(old)
                need(policy != "estate_legacy" or field.get("groups", []) == [], "ESTATE_331_OWNED_ONLY_NO_NEW_GROUP_CLOSURE")
                for group in field.get("groups", []):
                    additions = self.group(group)
                    for external in forbidden:
                        additions.pop(external, None)
                    self.merge(updated, additions)
                need(not (set(updated) & forbidden), "EXTERNAL_INDEX_OR_SELF_REVERSE_PIN_CYCLE")
                need(not any(p.startswith(prefix) for p in updated for prefix in row.get("forbidden_source_prefixes", [])), "SOURCE_DOMAIN_PREFIX_CYCLE")
                if policy == "estate_legacy":
                    need(set(updated) == set(pointer(base, field["pointer"])), "ESTATE_NATIVE_SOURCE_KEYSET_MUST_STAY_331")
                operation = {"op": "set", "pointer": field["pointer"], "existed": True, "old": old, "new": updated}
                deltas += self.change(value, [operation], True)
            if row.get("source_bundle"):
                bundle = row["source_bundle"]
                need(policy != "estate_legacy", "ESTATE_CANNOT_IMPORT_SHARED_BUNDLE")
                fields = bundle["fields"]
                originals = [copy.deepcopy(pointer(value, keys)) for keys in fields]
                updated = [self.promote_owned(v) for v in originals]
                need(all(isinstance(v, dict) for v in originals), "DISJOINT_SOURCE_FIELDS_MUST_BE_DICTIONARIES")
                for group in bundle.get("groups", []):
                    for path, sha in self.group(group).items():
                        if path in forbidden:
                            continue
                        need(not any(path.startswith(prefix) for prefix in row.get("forbidden_source_prefixes", [])), "BUNDLE_SOURCE_PREFIX_CYCLE")
                        existing = [i for i, values in enumerate(updated) if path in values]
                        need(len(existing) <= 1, "SOURCE_ALREADY_DUPLICATE_ACROSS_MANIFEST_CLASSES:" + path)
                        if existing:
                            self.merge(updated[existing[0]], {path: sha})
                        else:
                            destination = bundle["default_destination"]
                            for route in bundle.get("new_source_routes", []):
                                if path.startswith(route["prefix"]):
                                    destination = route["destination"]
                                    break
                            need(destination in fields, "DECLARED_SOURCE_CLASS_DESTINATION")
                            updated[fields.index(destination)][path] = sha
                for keys, old, new in zip(fields, originals, updated):
                    need(not (set(new) & forbidden), "BUNDLE_INDEX_OR_SELF_REVERSE_PIN_CYCLE")
                    if not same(old, new):
                        deltas += self.change(value, [{"op": "set", "pointer": keys, "existed": True, "old": old, "new": new}], True)
            for key in ("artifacts", "layout_proof", "mask_sha256", "geometry_proof_basis", "native_artifacts"):
                if key in base:
                    need(same(value.get(key), base[key]), "NATIVE_GEOMETRY_HISTORY_MUST_NOT_CHANGE:" + key)
            for keys in row.get("protected_pointers", []):
                need(same(pointer(base, keys), pointer(value, keys)), "PROTECTED_METADATA_POINTER")
            inverse = copy.deepcopy(value)
            for delta in reversed(deltas):
                holder, key = pointer(inverse, delta["pointer"][:-1]), delta["pointer"][-1]
                if delta["existed"]:
                    holder[key] = delta["old"]
                else:
                    del holder[key]
            need(same(inverse, base), "WHOLE_PARENT_METADATA_INVERSE")
            literal = row.get("literal_candidate_input")
            output_bytes = encode(value)
            if literal is not None:
                # One fixed data successor only; every source-only/inverse guard above still ran.
                need(row.get("target") == "res://data/luoyang_culture_integration_20261019x/runtime_contract.json", "LITERAL_ONLY_X_RUNTIME_CONTRACT")
                need(row.get("old_sha256") == "4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a" and self.inputs[row["base_input"]]["sha256"] == row["old_sha256"], "LITERAL_EXACT_X_B564_PARENT")
                need(isinstance(literal, str) and literal in self.inputs and self.inputs[literal]["sha256"] == "a4ac5f34715033bb59986cb152eb45413f4ccdaee591710f4e7db3136e16155d", "LITERAL_EXACT_X_4D931_PINNED_CANDIDATE")
                need(same(value, self.read_json_input(literal)), "LITERAL_CANDIDATE_MUST_EQUAL_FULLY_CHECKED_TYPED_SUCCESSOR")
                output_bytes = self.input_bytes[literal]
            path, sha = self.output(row["file"], output_bytes)
            self.nodes[ident] = {"path": path, "sha256": sha, "value": value}
            self.proofs[ident] = {"whole_typed_inverse": True, "source_delta": deltas, "geometry_native_history_unchanged": True}
            if literal is not None:
                self.proofs[ident]["literal_candidate_original_bytes"] = {"input": literal, "sha256": sha, "typed_equal_after_all_source_inverse_guards": True, "normalized": False}
            if derived_proof:
                self.proofs[ident]["pinned_actual_derived_parent_proof"] = derived_proof
        elif kind == "index":
            original = self.input_bytes[row["base_input"]].decode("utf-8")
            disabled = original
            replacements = []
            for hunk in row["replacements"]:
                new = self.value(hunk["new"])
                need(isinstance(new, str) and disabled.count(hunk["old"]) == 1, "INDEX_EXACT_ONE_LITERAL")
                disabled = disabled.replace(hunk["old"], new)
                replacements.append({"old": hunk["old"], "new": new})
            inverse = disabled
            for hunk in reversed(replacements):
                need(hunk["new"] and inverse.count(hunk["new"]) == 1, "INDEX_INVERSE_EXACT_ONE_LITERAL")
                inverse = inverse.replace(hunk["new"], hunk["old"])
            need(inverse == original, "INDEX_DISABLED_WHOLE_PARENT_BYTE_INVERSE")
            off, on = row["disabled_literal"], row["enabled_literal"]
            need(disabled.count(off) == 1 and off.count("false") == 1 and off.replace("false", "true") == on and on not in disabled, "INDEX_SOLE_DISABLED_BOOL")
            enabled = disabled.replace(off, on)
            need(enabled.replace(on, off) == disabled, "INDEX_BOOL_WHOLE_INVERSE")
            dp, ds = self.output(row["disabled_file"], disabled.encode("utf-8"))
            path, sha = self.output(row["file"], enabled.encode("utf-8"))
            self.nodes[ident] = {"path": path, "sha256": sha, "disabled_path": dp, "disabled_sha256": ds}
            self.proofs[ident] = {"disabled_to_enabled_sole_bool_whole_inverse": True, "disabled_sha256": ds}
        elif kind == "map":
            scene = row["scene_id"]
            need(scene in BASELINES, "FOUR_FIXED_MAPS_ONLY")
            expected, count = BASELINES[scene]
            seed = self.inputs[row["base_input"]]
            need(seed["path"] == BASE_ROOT + scene + "_true.json" and seed["sha256"] == expected and len(base["source_sha256"]) == count, "INDEPENDENT_FIXED_BASELINE")
            old = base["source_sha256"]
            value = {"source_sha256": self.promote_owned(old)}
            need(all(len(op.get("pointer", [])) == 2 and op["pointer"][0] == "source_sha256" for op in row.get("operations", [])), "MAP_FINITE_SOURCE_KEY_OPERATIONS_ONLY")
            deltas = self.change(value, row.get("operations", []))
            for group in row.get("groups", []):
                self.merge(value["source_sha256"], self.group(group))
            for path, sha in value["source_sha256"].items():
                self.verify_leaf(path, sha)
            added = set(value["source_sha256"]) - set(old)
            if scene != "ch4_s3_luoyang_market":
                need(not any(p.startswith("res://data/maps/luoyang_full_city_20261022ap/quarters/") for p in added), "ONLY_MARKET_ACQUIRES_NEW_QUARTER_NATIVE_CLOSURE")
            if scene == "ch4_s0_luoyang_gate":
                need(not any("/rooms/" in p or "/luoyang_layout_rooms_" in p for p in added), "GATE_MUST_NOT_ACQUIRE_ROOM253")
            removed = set(old) - set(value["source_sha256"])
            declared = {r["path"]: r for r in row.get("retired_runtime_authorities", [])}
            need(removed == set(declared), "NO_UNDECLARED_OLD_MAP_SOURCE_REMOVAL")
            for path in removed:
                need(path.endswith("/manifest.json") and declared[path]["old_sha256"] == old[path] and declared[path]["replacement"] in value["source_sha256"], "ONLY_EXPLICIT_REPLACED_RUNTIME_AUTHORITY")
            output = {"status": "AP_INDEPENDENT_EXPECTED_NOT_ACTUAL_COLLECTOR", "baseline_path": seed["path"], "baseline_sha256": expected, "scene_id": scene, "source_sha256": value["source_sha256"]}
            media = self.media_closure(output["source_sha256"], row.get("runtime_media_roots", []))
            path, sha = self.output(row["file"], encode(output))
            self.nodes[ident] = {"path": path, "sha256": sha, "value": output}
            self.proofs[ident] = {"baseline_count": count, "count": len(output["source_sha256"]), "explicit_delta": deltas, "retired_runtime_authorities": list(removed), "runtime_media_closure": media, "no_collector_or_current_disk_derivation": True}
        else:
            raise ValueError("UNKNOWN_NODE_KIND")
        if "target" in row:
            self.target(row["target"], row["old_sha256"], path, sha)

    def run(self):
        need(self.spec.get("status") == "ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT" and self.spec.get("blockers") == [], "ROOT_LOCKED_NO_PENDING_BLOCKERS_REQUIRED")
        gates = self.spec.get("required_gates", [])
        need({r["id"] for r in gates} == REQUIRED_GATES, "ALL_FIVE_EXPLICIT_ROOT_NATIVE_PERMISSION_GATES")
        for gate in gates:
            need(same(pointer(self.read_json_input(gate["input"]), gate["pointer"]), gate["equals"]), "REQUIRED_GATE_NOT_GRANTED:" + gate["id"])
        for row in self.spec.get("pass_through_targets", []):
            row = copy.deepcopy(row)
            if row.get("candidate_from_authority") is True:
                need(row["target"] in self.authority["owned"], "AUTHORITY_CANDIDATE_CLOSED_DOMAIN")
                frozen = self.prospective[row["target"]]
                row["candidate_path"] = frozen["candidate_path"]
                row["candidate_sha256"] = frozen["sha256"]
            self.read(row["candidate_path"], row["candidate_sha256"])
            if row["target"] in OWNED:
                need(row["target"] in self.authority["owned"] and self.authority["owned"][row["target"]]["current_sha256"] == row["candidate_sha256"], "TARGET_NOT_FROZEN_OWNED_CURRENT")
            elif row.get("target") == "res://data/maps/luoyang_full_city_20261022ap/execution_successor.json" and row.get("old_sha256") == "80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11" and row.get("candidate_sha256") == "fef4cba7be47faf14b72598b7a2f3f8867f792e3fb6c9c006fb9bda8dd2b589c":
                root_pin = self.inputs.get("root_unified_execution_approval", {})
                need(root_pin.get("sha256") == "318ce82bd6d59dfa3203d365a1d67a45ea5b19d5750535c36fa2224e300c8c15" and self.read_json_input("root_unified_execution_approval").get("approved_by_root") is True, "EXACT318C_ROOT_80A_FEF4_APPROVAL_REQUIRED")
                need(self.inputs[self.spec["authority_input"]]["sha256"] == row["candidate_sha256"] and self.inputs[self.spec["authority_input"]]["path"] == row["candidate_path"], "EXACT_FEF4_VALIDATED_AUTHORITY_INPUT")
                prior = json.loads(self.read(row["target"], row["old_sha256"]))
                changed = {"res://scripts/autoload/scene_router.gd", "res://scripts/field/field_walkable_controller.gd", "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd", "res://scripts/city/luoyang_temple_assembly_20261016.gd"}
                need(set(prior["owned"]) == set(self.authority["owned"]) and len(prior["owned"]) == 10, "UNCHANGED_OWNED10_DOMAIN")
                restored = copy.deepcopy(self.authority)
                for p, previous in prior["owned"].items():
                    current = self.authority["owned"][p]
                    if p not in changed:
                        need(same(previous, current), "UNCHANGED_OTHER6_OWNED_ROWS")
                    else:
                        need(len(current["edges"]) == len(previous["edges"]) + 1 and same(current["edges"][:-1], previous["edges"]), "EXACT_ONE_APPENDED_EDGE_OLD_GRAPH_PRESERVED")
                        edge = current["edges"][-1]
                        need(edge["old_sha256"] == previous["current_sha256"] and edge["new_sha256"] == current["current_sha256"], "PREDECESSOR_CURRENT_TO_NEW_CURRENT_EDGE")
                        restored["owned"][p] = copy.deepcopy(previous)
                need(len(prior["source_sha256"]) == 37 and len(self.authority["source_sha256"]) == 44 and all(self.authority["source_sha256"].get(p) == v for p, v in prior["source_sha256"].items()), "OLD37_PINS_PRESERVED_EXACT7_ADDED")
                restored["source_sha256"] = copy.deepcopy(prior["source_sha256"])
                need(same(restored, prior), "WHOLE_TYPED_INVERSE_EXACT80A")
            elif row.get("system_offset_candidate") is True:
                need(self.inputs["unified_system_candidates"]["sha256"] == "84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee", "EXACT84CEE_SYSTEM_SET")
                system = self.read_json_input("unified_system_candidates")
                matches = [r for r in system["targets"] if r["canonical"] == row["target"]]
                need(len(matches) == 1 and row["target"] not in OWNED, "FIXED_NONOWNED_SYSTEM_TARGET")
                proof = matches[0]
                need(proof["parent_sha256"] == row["old_sha256"] and proof["candidate"]["path"] == row["candidate_path"] and proof["candidate"]["sha256"] == row["candidate_sha256"], "FIXED_SYSTEM_TARGET_PARENT_CANDIDATE")
                before = self.read(row["target"], row["old_sha256"])
                after = self.read(row["candidate_path"], row["candidate_sha256"])
                oc = nc = 0
                for h in proof["offset_byte_hunks"]:
                    o, n = h["old_offset"], h["new_offset"]
                    a, b = base64.b64decode(h["old_b64"]), base64.b64decode(h["new_b64"])
                    need(before[oc:o] == after[nc:n] and before[o:o+len(a)] == a and after[n:n+len(b)] == b, "SYSTEM_EXACT_OFFSET_BYTE_HUNK")
                    oc, nc = o+len(a), n+len(b)
                need(before[oc:] == after[nc:], "SYSTEM_EXACT_OFFSET_BYTE_TAIL")
                inverse = after
                for h in reversed(proof["offset_byte_hunks"]):
                    n = h["new_offset"]
                    a, b = base64.b64decode(h["old_b64"]), base64.b64decode(h["new_b64"])
                    need(inverse[n:n+len(b)] == b, "SYSTEM_INVERSE_EXACT_COORDINATE")
                    inverse = inverse[:n] + a + inverse[n+len(b):]
                need(inverse == before, "SYSTEM_NONOWNED_WHOLE_BYTE_INVERSE")
            elif row["old_sha256"] != "ABSENT":
                need(row["target"].endswith(".gd"), "EXISTING_DATA_MUST_USE_TYPED_METADATA_NODE_NOT_OPAQUE_COPY")
                old = self.read(row["target"], row["old_sha256"])
                new = self.read(row["candidate_path"], row["candidate_sha256"]).decode("utf-8")
                need(row.get("exact_replacements"), "NONOWNED_EXISTING_HELPER_EXACT_HUNKS_REQUIRED")
                for hunk in row["exact_replacements"]:
                    need(hunk["new"] and new.count(hunk["new"]) == 1, "NONOWNED_HELPER_UNIQUE_NEW_HUNK")
                    new = new.replace(hunk["new"], hunk["old"])
                need(new.encode("utf-8") == old, "NONOWNED_HELPER_WHOLE_BYTE_INVERSE")
            self.target(row["target"], row["old_sha256"], row["candidate_path"], row["candidate_sha256"])
        for row in self.spec.get("nodes", []):
            self.build_node(row)
        maps = [r for r in self.spec["nodes"] if r["kind"] == "map"]
        need({r["scene_id"] for r in maps} == set(BASELINES), "ALL_FOUR_INDEPENDENT_EXPECTED_MAPS_REQUIRED")
        need(self.spec["common_group"] in self.groups and all(self.spec["common_group"] in r.get("groups", []) for r in maps), "ALL_FOUR_MAPS_EXPLICIT_COMMON_SOURCE_GROUP")
        need(set(self.targets) == set(self.spec["root_target_allowlist"]), "FINITE_ROOT_TARGET_SET_EXACT")
        patch = ["*** Begin Patch\n"]
        patch_reconstruction = {}
        patch_targets, copy_rows = set(), []
        copy_target = "res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
        copy_candidate = self.inputs[self.spec["authority_input"]]["path"]
        copy_sha = self.inputs[self.spec["authority_input"]]["sha256"]
        copy_parent_sha = "80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11"
        for row in self.targets.values():
            path = row["candidate_path"]
            candidate = self.outputs[path] if path in self.outputs else self.read(path, row["candidate_sha256"])
            before = None if row["old_sha256"] == "ABSENT" else self.read(row["target"], row["old_sha256"])
            if row["target"] == copy_target:
                # Second narrow epoch: only the existing canonical approval9C3F
                # may advance to the fully validated externally-pinned new Root
                # approval. No GD/other JSON EOL domain is relaxed or normalized.
                need(before is not None and row["old_sha256"] == copy_parent_sha and digest(before) == copy_parent_sha and path == copy_candidate and row["candidate_sha256"] == copy_sha and digest(candidate) == copy_sha and copy_sha != copy_parent_sha, "EXACT_ONE_EXISTING_9C3F_APPROVAL_ROOT_PINNED_SUCCESSOR_BYTE_COPY_ONLY")
                need(len(before) == 158070 and before.count(b"\r\n") == 0 and before.count(b"\r") == 0 and before.count(b"\n") == 614 and before.endswith(b"\n") is True, "FROZEN80A_PARENT_ORIGINAL_BYTES_EOL_DOMAIN")
                copy_rows.append({**row, "candidate_bytes": len(candidate), "mechanism": "EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION", "exact_existing_parent_sha256": copy_parent_sha})
                patch_reconstruction[row["target"]] = {"kind": "ExactMechanicalByteCopy", "candidate_sha256": copy_sha, "candidate_bytes": len(candidate), "original_bytes_preserved": True, "normalized": False, "not_an_apply_patch_payload": True}
                continue
            piece, proof = build_file_patch(res(row["target"]).as_posix(), before, candidate)
            patch.append(piece)
            patch_reconstruction[row["target"]] = proof
            patch_targets.add(row["target"])
        patch.append("*** End Patch\n")
        copy_targets = {r["target"] for r in copy_rows}
        need(copy_targets == {copy_target} and len(copy_rows) == 1 and 1 <= len(patch_targets) < 37 and not (patch_targets & copy_targets) and patch_targets | copy_targets == set(self.targets) == set(self.spec["root_target_allowlist"]), "NARROW_ROOT_ALLOWLIST_DISJOINT_PATCH_N_PLUS_EXACT_COPY1_TARGET_PARTITION")
        byte_plan_path, byte_plan_sha = self.output("canonical_byte_copy_plan.json", encode({"status": "ROOT_ONLY_EXISTING_9C3F_APPROVAL_SUCCESSOR_BYTE_COPY_NOT_EXECUTED", "rows": copy_rows, "patch_targets": sorted(patch_targets), "copy_targets": sorted(copy_targets), "target_count": len(self.targets), "patch_copy_disjoint": True, "patch_copy_union_exact_targets": True, "canonical_written": False}))
        pp, ps = self.output("canonical_deployment.apply_patch", "".join(patch).encode("utf-8"))
        final = {p: digest(res(p).read_bytes()) for p in self.first}
        need(final == self.first, "SOURCE_FIRST_FINAL_DRIFT")
        receipt = {"status": "AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED", "targets": list(self.targets.values()), "nodes": self.nodes, "proofs": self.proofs, "source_first": self.first, "source_final": final, "patch_path": pp, "patch_sha256": ps, "patch_reconstruction": patch_reconstruction, "patch_line_domain": "Literal old EOL payload; candidates UTF8/LF/final LF only; CRLF/no-final-LF candidates fail closed without normalization", "no_engine_import_collector_or_canonical_write": True, "single_root_atomic_epoch_required": True}
        receipt["byte_copy_plan"] = {"path": byte_plan_path, "sha256": byte_plan_sha, "target_count": 1, "sole_candidate_sha256": copy_sha, "original_bytes_preserved": True, "normalized": False}
        receipt["target_partition"] = {"patch_count": len(patch_targets), "copy_count": 1, "total": len(self.targets), "intersection_empty": True, "union_exact_targets": True}
        receipt["patch_line_domain"] += "; sole fixed existing execution_successor9C3F JSON advances to Root-pinned approved successor via exact mechanical byte-copy plan, no GD/EOL relaxation"
        self.output("receipt.json", encode(receipt))
        need(not res(self.out).exists(), "OUTPUT_CREATED_DURING_PREFLIGHT")
        for path, data in self.outputs.items():
            destination = res(path)
            destination.parent.mkdir(parents=True, exist_ok=True)
            with destination.open("xb") as stream:
                stream.write(data)
        return {"output_root": self.out, "targets": len(self.targets), "map_nodes": len(maps), "receipt_sha256": digest(self.outputs[self.out + "receipt.json"])}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Root-locked explicit JSON plan; no defaults inferred")
    parser.add_argument("--input-sha256", help="Mandatory external pin for an actual stage run")
    parser.add_argument("--inspect-plan", action="store_true", help="Read-only missing-input summary; never writes stage files")
    args = parser.parse_args()
    plan_path = Path(args.input).resolve()
    need(plan_path.is_relative_to(ROOT), "LOCKED_PLAN_MUST_BE_IN_GAME_WORKSPACE")
    plan_bytes = plan_path.read_bytes()
    spec = json.loads(plan_bytes)
    need(spec.get("schema_version") == 1, "SCHEMA_VERSION")
    if args.inspect_plan:
        print(json.dumps({"status": spec.get("status"), "blockers": spec.get("blockers", []), "missing_gate_ids": sorted(REQUIRED_GATES - {r["id"] for r in spec.get("required_gates", [])}), "not_a_READY_stage": True, "canonical_written": False}, ensure_ascii=False))
        return
    need(valid_sha(args.input_sha256) and digest(plan_bytes) == args.input_sha256, "ROOT_LOCKED_PLAN_EXTERNAL_SHA_REQUIRED")
    spec["_locked_plan"] = {"path": "res://" + plan_path.relative_to(ROOT).as_posix(), "sha256": args.input_sha256}
    print(json.dumps(Stage(spec).run(), ensure_ascii=False))


if __name__ == "__main__":
    main()
