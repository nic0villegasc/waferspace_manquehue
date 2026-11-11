#!/usr/bin/env python3
"""Get the macros of sources.yaml into macros/<name>/ and check each file against its SHA-256 (make fetch).

usage: python3 scripts/fetch.py [--check] [name ...]   (default: every macro in sources.yaml)
       --check only reports what is missing or changed (make doctor), and downloads nothing.

A macro whose files all match is left alone, so make fetch is cheap to run before every target. A missing or
changed file is fetched again from the macro's source, and checked again:
  release: {repo: owner/name, tag: <tag>, asset: <file.tar.gz>}   a GitHub release (gh release download)
  git:     {repo: owner/name, ref: <commit>, path: <dir>}         files of a repository at a commit (gh api)
  path:    <folder>                                               a local folder, for a run not published yet
  manual:  <where to get it>                                      no download: the file must be put there by hand
An entry goes to macros/<name>/, or to macros/<dest>/ when it has dest:.
"""
import hashlib
import shutil
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))   # sources.py next to this script
import sources

ROOT = Path(__file__).resolve().parents[1]
SOURCES = sources.load()


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def bad_files(dest, files):
    """Files that are missing or do not match their SHA-256."""
    return [f for f, want in files.items() if not (dest / f).is_file() or sha256(dest / f) != want]


def gh(*args):
    subprocess.run(["gh", *args], check=True, stdout=subprocess.DEVNULL)


def get(name, spec, dest, files):
    """Copy the files of one macro from its source into dest."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        if "release" in spec:
            r = spec["release"]
            gh("release", "download", r["tag"], "--repo", r["repo"], "--pattern", r["asset"], "--dir", str(tmp))
            with tarfile.open(tmp / r["asset"]) as t:
                t.extractall(tmp / "x")
            src = tmp / "x"
        elif "git" in spec:
            g = spec["git"]
            src = tmp
            for f in files:
                out = tmp / f
                out.parent.mkdir(parents=True, exist_ok=True)
                with open(out, "wb") as o:
                    subprocess.run(["gh", "api", "-H", "Accept: application/vnd.github.raw",
                                    "repos/%s/contents/%s/%s?ref=%s" % (g["repo"], g["path"], f, g["ref"])],
                                   check=True, stdout=o)
        elif "path" in spec:
            src = Path(spec["path"]).expanduser()
        else:
            raise SystemExit("fetch: %s: get %s by hand: %s" % (name, ", ".join(bad_files(dest, files)), spec.get("manual", "?")))
        for f in files:
            if not (src / f).is_file():
                raise SystemExit("fetch: %s: %s is not in the source" % (name, f))
            (dest / f).parent.mkdir(parents=True, exist_ok=True)
            if (dest / f).is_symlink():
                (dest / f).unlink()
            shutil.copyfile(src / f, dest / f)


args = sys.argv[1:]
check = "--check" in args
names = [a for a in args if a != "--check"] or list(SOURCES)
bad_total = 0
for name in names:
    spec = SOURCES[name]
    dest = ROOT / "macros" / spec.get("dest", name)   # several entries can fill one folder
    if dest.is_symlink():                       # an old link (make macro) gives way to a real folder
        dest.unlink()
    dest.mkdir(parents=True, exist_ok=True)
    files = spec["files"]
    if not bad_files(dest, files):
        print("fetch: %-8s up to date (%d files)" % (name, len(files)))
        continue
    if check:
        bad_total += 1
        print("fetch: %-8s MISSING or changed: %s" % (name, ", ".join(bad_files(dest, files))))
        continue
    get(name, spec, dest, files)
    still = bad_files(dest, files)
    if still:
        raise SystemExit("fetch: %s: SHA-256 does not match after the download: %s" % (name, ", ".join(still)))
    print("fetch: %-8s fetched and checked (%d files)" % (name, len(files)))
if check and bad_total:
    sys.exit(1)
