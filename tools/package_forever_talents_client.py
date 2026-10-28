"""Build isolated native client MPQ candidate: FrameXML Lua plus approved portrait art."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from package_hotspot_client import package


ROOT = Path(__file__).resolve().parents[1]
ART_NAMES = ("moon_priest", "sentinel", "warden", "moon_guard")


def sha(path):
    value = hashlib.sha256()
    with open(path, "rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--mpqcli", required=True, type=Path)
    parser.add_argument("--assets", required=True, type=Path)
    args = parser.parse_args()

    assets = args.assets.resolve()
    expected = {name: assets / (name + ".tga") for name in ART_NAMES}
    missing = [str(path) for path in expected.values() if not path.is_file()]
    if missing:
        raise FileNotFoundError("Missing approved portrait art: " + ", ".join(missing))

    baseline, output = args.baseline.resolve(), args.output.resolve()
    if output.exists() or baseline == output:
        raise ValueError("Output must be a new candidate archive, not the baseline")
    baseline_hash = sha(baseline)
    report = package(baseline, output, args.mpqcli, lua_files=["ForeverCoATalents.lua"])

    def run(*parts):
        process = subprocess.run([str(args.mpqcli.resolve()), *map(str, parts)],
                                 text=True, capture_output=True)
        if process.returncode:
            raise RuntimeError(process.stderr or process.stdout or "mpqcli failed")

    for name, path in expected.items():
        member = r"Interface\AzerothForever\Talents" + "\\" + name + ".tga"
        run("add", "--overwrite", "--game", "wow-wotlk", "--path", member, output, path)

    with tempfile.TemporaryDirectory(prefix="forever-art-", dir=output.parent) as tmp:
        unpacked = Path(tmp) / "unpacked"
        run("extract", "--keep", "--output", unpacked, output)
        for name, path in expected.items():
            member = (unpacked / "Interface" / "AzerothForever" / "Talents" /
                      (name + ".tga"))
            if not member.is_file():
                hits = list(unpacked.rglob(name + ".tga"))
                member = hits[0] if len(hits) == 1 else member
            if not member.is_file() or sha(member) != sha(path):
                raise RuntimeError("Art readback differs: " + name)
    if sha(baseline) != baseline_hash:
        raise RuntimeError("Baseline was modified; candidate must be discarded")
    report["candidate_sha256"] = sha(output)
    report["art_members"] = list(ART_NAMES)
    report["state"] = "built and art verified; NOT installed or game-tested"
    report["in_game_tested"] = False
    output.with_suffix(output.suffix + ".json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
