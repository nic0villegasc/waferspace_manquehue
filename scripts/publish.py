#!/usr/bin/env python3
"""Record a new version of a macro in sources.yaml, and publish it as a GitHub release (make publish).

usage: python3 scripts/publish.py <name> <folder> [--repo owner/name --tag <tag>] [--dest <dir>] [--note <text>]

  with --repo and --tag   pack every file of <folder> into <name>-<tag>.tar.gz, create the release <tag> in that
                          repository with the archive, and point the entry at it. Anyone with read access gets it
                          with make fetch.
  without them            point the entry at <folder> as it is (a local version, for your machine only).

Every file of <folder> goes in, with its SHA-256. Commit sources.yaml afterwards.
"""
import argparse
import hashlib
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))   # sources.py next to this script
import sources as src

ROOT = Path(__file__).resolve().parents[1]

ap = argparse.ArgumentParser()
ap.add_argument("name")
ap.add_argument("folder")
ap.add_argument("--repo")
ap.add_argument("--tag")
ap.add_argument("--dest")
ap.add_argument("--note")
a = ap.parse_args()
if bool(a.repo) != bool(a.tag):
    sys.exit("publish: give --repo and --tag together, or neither")

folder = Path(a.folder).expanduser().resolve()
files = sorted(p for p in folder.rglob("*") if p.is_file() and not any(x.startswith(".") for x in p.relative_to(folder).parts))
if not files:
    sys.exit("publish: no files in %s" % folder)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


sources = src.load()
entry = {k: v for k, v in sources.get(a.name, {}).items() if k in ("note", "dest")}
if a.note:
    entry["note"] = a.note
if a.dest:
    entry["dest"] = a.dest

if a.repo:
    asset = (a.tag if a.tag.startswith(a.name) else "%s-%s" % (a.name, a.tag)) + ".tar.gz"   # croc-v2.tar.gz, not croc-croc-v2
    with tempfile.TemporaryDirectory() as tmp:
        arc = Path(tmp) / asset
        with tarfile.open(arc, "w:gz") as t:
            for p in files:
                t.add(p, arcname=str(p.relative_to(folder)))
        subprocess.run(["gh", "release", "create", a.tag, str(arc), "--repo", a.repo, "--title", "%s %s" % (a.name, a.tag),
                        "--notes", "%s for the AC3E chip (%d files). Fetched by make fetch." % (a.name, len(files))], check=True)
    entry["release"] = {"repo": a.repo, "tag": a.tag, "asset": asset}
else:
    home = str(Path.home())
    entry["path"] = "~" + str(folder)[len(home):] if str(folder).startswith(home + "/") else str(folder)
entry["files"] = {str(p.relative_to(folder)): sha256(p) for p in files}
sources[a.name] = entry



src.save(sources)
print("publish: %s -> %s (%d files). Commit sources.yaml." % (
    a.name, "release %s of %s" % (a.tag, a.repo) if a.repo else entry["path"], len(files)))
