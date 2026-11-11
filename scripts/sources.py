"""Read and write sources.yaml with plain Python (no PyYAML needed).

The file is a small YAML subset: an entry per macro, its keys at two spaces, and the keys of release, git and files
at four. A value is plain text, or a JSON string in quotes when it holds ": " or " #".
"""
import json
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / "sources.yaml"
HEAD = """# The macros of the chip: where each one comes from and the SHA-256 of every file. make fetch puts them in
# macros/<name>/ (or macros/<dest>/) and fetches again only what is missing or changed. A new version comes in
# with make publish (see the README). Do not edit the hashes by hand.
"""
ORDER = ("note", "dest", "release", "git", "path", "manual", "files")


def _value(v):
    return json.loads(v) if v.startswith('"') else v


def load():
    entries, entry, sub = {}, None, None
    for line in PATH.read_text().splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip(" "))
        key, _, val = line.strip().partition(":")
        val = val.strip()
        if indent == 0:
            entry = entries[key] = {}
        elif indent == 2:
            if val:
                entry[key] = _value(val)
            else:
                sub = entry[key] = {}
        else:
            sub[key] = _value(val)
    return entries


def _scalar(v):
    v = str(v)
    return json.dumps(v) if (": " in v or " #" in v or v[:1] in "&*!|>'\"%@`{[") else v


def save(entries):
    blocks = []
    for name, e in entries.items():
        out = ["%s:" % name]
        for k in ORDER:
            if k not in e:
                continue
            if isinstance(e[k], dict):
                out.append("  %s:" % k)
                out += ["    %s: %s" % (kk, _scalar(vv)) for kk, vv in e[k].items()]
            else:
                out.append("  %s: %s" % (k, _scalar(e[k])))
        blocks.append("\n".join(out) + "\n")
    PATH.write_text(HEAD + "\n" + "\n".join(blocks))
