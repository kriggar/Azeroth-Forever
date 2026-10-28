#!/usr/bin/env python3
"""Build a *native FrameXML* full-UI MPQ from the GPL-2.0 ForeverUI port.

The UI source is fetched separately from Adrestie/mod-forever-ui at a pinned
commit. This program packages the in-game interface scripts, as built-in
FrameXML files, NOT as Interface/AddOns/ForeverUI. CoA login/character creation
GlueXML is deliberately excluded to preserve its 21 custom classes.

Never alters installed game executables, databases, source MPQs or WTF settings.
Requires mpqcli 0.11.0+ (StormLib) to build/verify an overlay.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

UPSTREAM_COMMIT = "c5149b96a9938ae9073ff8bb1662e42d2b7b5090"
TOC_MEMBER = "Interface/FrameXML/FrameXML.toc"
NATIVE_FOLDER = "Interface/FrameXML/AzerothForeverNative"
SOURCE_FOLDER = "data/addon/ForeverUI"
ROOT = Path(__file__).resolve().parent
BOOT_FILES = ("AzerothForeverNativeBegin.lua", "AzerothForeverNativeEnd.lua")
UPSTREAM_UI_FILES = ("UIAtlas.lua", "PlayerFrame.lua", "ActionBar.lua",
                     "BottomBar.lua", "QuestLog.lua", "Achievements.lua",
                     "CharacterFrame.lua", "SpellBook.lua", "Talents.lua")

def digest(file):
    h = hashlib.sha256()
    with open(file, "rb") as f:
        for part in iter(lambda: f.read(1024 * 1024), b""):
            h.update(part)
    return h.hexdigest()

def check_relative(p):
    pp = Path(p.replace("\\", "/"))
    if pp.is_absolute() or ".." in pp.parts or not pp.parts:
        raise ValueError("Unsafe source path: " + str(p))
    return pp

def read_upstream_toc(folder):
    toc = folder / SOURCE_FOLDER / "ForeverUI.toc"
    if not toc.is_file():
        raise ValueError("Missing pinned ForeverUI source toc: " + str(toc))
    result = []
    for line in toc.read_text("utf-8-sig").splitlines():
        line = line.strip().replace("\\", "/")
        if not line or line.startswith("#"):
            continue
        file = check_relative(line)
        if file.suffix.lower() != ".lua" or len(file.parts) != 1:
            raise ValueError("Unexpected addon entry: " + line)
        if file in result:
            raise ValueError("Repeated UI script: " + line)
        if not (toc.parent / file).is_file():
            raise ValueError("Missing full UI script: " + str(file))
        result.append(file)
    if len(result) < 90 or any(Path(f) not in result for f in UPSTREAM_UI_FILES):
        raise ValueError("Incomplete full-interface source: refuse toolbar-only package")
    return result

def extend_framexml(original, entries):
    # Keep CoA's *existing* FrameXML.toc and its load order intact.
    if original.startswith(b"\xef\xbb\xbf"):
        text = original[3:].decode("utf-8")
        bom = b"\xef\xbb\xbf"
    else:
        text = original.decode("utf-8")
        bom = b""
    if "AzerothForeverNativeBegin.lua" in text:
        raise ValueError("Already native-patched FrameXML.toc; restore the source archive first")
    newline = "\r\n" if "\r\n" in text else "\n"
    if not re.search(r"(?im)^\s*UIParent\.lua\s*$", text):
        raise ValueError("Unrecognized CoA FrameXML.toc (UIParent.lua not found)")
    if not text.endswith(("\r", "\n")):
        text += newline
    text += newline + "# Azeroth Forever - native full UI (not an AddOn)" + newline
    for entry in entries:
        text += entry.replace("/", "\\") + newline
    return bom + text.encode("utf-8")

def run(exe, *args):
    proc = subprocess.run([str(exe), *map(str, args)], capture_output=True,
                          text=True, encoding="utf-8", errors="replace")
    if proc.returncode != 0:
        raise RuntimeError("MPQ command failed: " + " ".join(map(str, args)) +
                           "\n" + (proc.stderr or proc.stdout)[-3000:])
    return proc.stdout

def extract_toc(mpqcli, archive, directory):
    # mpqcli 0.11 expects <archive> <member> before option flags when
    # extracting a specific file. The previous ordering failed on real MPQs.
    run(mpqcli, "extract", archive, TOC_MEMBER.replace("/", "\\"),
        "--output", directory)
    matches = [p for p in Path(directory).rglob("*")
               if p.is_file() and p.as_posix().lower().endswith("interface/framexml/framexml.toc")]
    if len(matches) != 1:
        raise RuntimeError("Effective FrameXML.toc not found or ambiguous in archive " + str(archive))
    return matches[0].read_bytes()

def stage(upstream, baseline_toc, staging):
    upstream = Path(upstream).resolve()
    staging = Path(staging).resolve()
    if not (upstream / "LICENSE").is_file():
        raise ValueError("Missing upstream GPL-2.0 license")
    source = upstream / SOURCE_FOLDER
    files = read_upstream_toc(upstream)
    framexml = staging / "Interface" / "FrameXML"
    native = staging / NATIVE_FOLDER
    native.mkdir(parents=True, exist_ok=True)
    for f in files:
        shutil.copy2(source / f, native / f)
    for name in BOOT_FILES:
        shutil.copy2(ROOT / "client" / name, framexml / name)

    art = upstream / "data" / "art" / "interface"
    if not art.is_dir() or not (art / "foreverui").is_dir():
        raise ValueError("Missing upstream full-interface artwork")
    target_art = staging / "Interface"
    for child in art.iterdir():
        if child.is_symlink():
            raise ValueError("Symlink in upstream artwork")
        dest = target_art / child.name
        if child.is_dir():
            shutil.copytree(child, dest, dirs_exist_ok=True)
        elif child.is_file():
            shutil.copy2(child, dest)

    # Omit GlueXML so CoA custom class creation/login screens stay intact.
    entries = [BOOT_FILES[0]]
    entries += [("AzerothForeverNative/" + str(f).replace("/", "\\")) for f in files]
    entries += [BOOT_FILES[1]]
    (framexml / "FrameXML.toc").write_bytes(extend_framexml(baseline_toc, entries))
    return {
        "ui_modules": len(files),
        "native_loader_entries": len(entries),
        "source_commit": UPSTREAM_COMMIT,
        "art_files": sum(1 for p in art.rglob("*") if p.is_file()),
        "client_glue_modified": False,
        "client_executable_modified": False,
        "client_addons_installed": False,
    }

def compare_inventory(expected, extracted):
    names = set()
    for p in expected.rglob("*"):
        if p.is_file():
            names.add(p.relative_to(expected).as_posix().lower())
            counterpart = extracted / p.relative_to(expected)
            if not counterpart.exists() or digest(p) != digest(counterpart):
                raise RuntimeError("MPQ readback mismatch: " + str(p))
    # mpqcli creates a (listfile) and may create internal MPQ metadata.
    extra = [p.relative_to(extracted).as_posix() for p in extracted.rglob("*")
             if p.is_file() and p.relative_to(extracted).as_posix().lower() not in names
             and p.name.lower() not in ("(listfile)", "(attributes)", "(signature)")]
    if extra:
        raise RuntimeError("Unexpected MPQ members: " + ", ".join(extra[:10]))
    return len(names)


def normalize_archive_name(name):
    return name.replace("\\", "/").strip().lower()


def files_by_archive_name(directory):
    """Map each extracted member to a lowercased MPQ path for safe comparison."""
    result = {}
    for file in Path(directory).rglob("*"):
        if not file.is_file():
            continue
        name = normalize_archive_name(file.relative_to(directory).as_posix())
        if name in result:
            raise ValueError("Case-colliding archive paths: " + name)
        result[name] = file
    return result


INTERNAL_MEMBERS = {"(listfile)", "(attributes)", "(signature)"}


def known_archive_names(mpqcli, archive):
    """Refuse to alter a patch whose contents cannot be fully inventoried."""
    output = run(mpqcli, "list", "-a", archive)
    names = [normalize_archive_name(line) for line in output.splitlines() if line.strip()]
    if len(names) != len(set(names)):
        raise ValueError("MPQ contains duplicate/locale-specific paths; cannot safely merge")
    try:
        declared_count = int(run(mpqcli, "info", "--property", "file-count", archive).strip())
    except ValueError as error:
        raise ValueError("Cannot determine existing MPQ file count") from error
    if len(names) != declared_count:
        raise ValueError(
            "Existing MPQ has unlisted members ({} listed, {} declared); "
            "refusing a potentially destructive merge".format(len(names), declared_count)
        )
    return set(names)


def merge_existing_patch(mpqcli, existing, payload, output, temp):
    """Copy a pre-existing CoA patch-Z, change the TOC, and add only native UI files.

    Existing content never changes unless it is the single explicit
    Interface/FrameXML/FrameXML.toc update, which retains its original lines.
    Validate every original and newly added extracted file by SHA-256.
    """
    if Path(existing).resolve() == Path(output).resolve():
        raise ValueError("Must not modify the installed original MPQ in place")
    if not Path(existing).is_file():
        raise ValueError("Existing MPQ is missing: " + str(existing))

    signature = run(mpqcli, "info", "--property", "signature-type", existing).strip().lower()
    if signature not in {"none", "no signature", "unsigned"}:
        raise ValueError(
            "Existing patch has an MPQ signature ({}) that merging would invalidate. "
            "The source patch is unchanged; use a separate compatible client patch.".format(signature)
        )

    old_names = known_archive_names(mpqcli, existing)
    original = temp / "original"
    run(mpqcli, "extract", "--keep", "--output", original, existing)
    old = files_by_archive_name(original)
    # Internal names may not be extractable; normal members must match *all* listed paths.
    normal_names = old_names - INTERNAL_MEMBERS
    if set(old) - INTERNAL_MEMBERS != normal_names:
        missing = normal_names - set(old)
        extra = (set(old) - INTERNAL_MEMBERS) - normal_names
        raise ValueError(
            "Existing CoA MPQ couldn't be fully verified (missing: {}, extra: {}). "
            "No client files changed".format(list(sorted(missing))[:5], list(sorted(extra))[:5])
        )

    new = files_by_archive_name(payload)
    collisions = set(old) & set(new)
    approved = {normalize_archive_name(TOC_MEMBER)}
    if collisions - approved:
        raise ValueError(
            "Native UI collides with CoA patch files: {}. "
            "Refusing to overwrite any CoA asset other than FrameXML.toc".format(
                ", ".join(sorted(collisions - approved)[:12])
            )
        )

    original_sha = digest(existing)
    shutil.copy2(existing, output)
    try:
        run(mpqcli, "add", output, payload, "--overwrite", "--game", "wow-wotlk")
        verified = temp / "merged-verify"
        run(mpqcli, "extract", "--keep", "--output", verified, output)
        final = files_by_archive_name(verified)

        expected_names = (set(old) | set(new)) - INTERNAL_MEMBERS
        if set(final) - INTERNAL_MEMBERS != expected_names:
            missing = expected_names - set(final)
            unexpected = (set(final) - INTERNAL_MEMBERS) - expected_names
            raise RuntimeError(
                "Merged archive inventory differs (missing: {}, unexpected: {})".format(
                    list(sorted(missing))[:8], list(sorted(unexpected))[:8])
            )

        for name in expected_names:
            wanted = new[name] if name in new else old[name]
            if digest(final[name]) != digest(wanted):
                raise RuntimeError("CoA MPQ entry was corrupted/overwritten: " + name)

        if digest(existing) != original_sha:
            raise RuntimeError("The original CoA patch changed during build; aborting")
        return {
            "merged_existing_patch": True,
            "original_patch_sha256": original_sha,
            "original_members_verified": len(set(old) - INTERNAL_MEMBERS - collisions),
            "ui_collisions_approved": sorted(collisions),
            "verified_members": len(expected_names)
        }
    except Exception:
        if Path(output).exists():
            Path(output).unlink()
        raise


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--upstream", type=Path, required=True,
                   help="Extracted Adrestie/mod-forever-ui at pinned commit")
    t = p.add_mutually_exclusive_group(required=True)
    t.add_argument("--toc-archive", type=Path,
                   help="CoA client MPQ containing the effective FrameXML.toc (usually patch-B.MPQ)")
    t.add_argument("--toc-file", type=Path,
                   help="Already extracted FrameXML.toc; useful for dry-run tests")
    p.add_argument("--mpqcli", type=Path, help="Pinned mpqcli executable")
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--merge-archive", type=Path,
                   help="Existing client patch-Z.MPQ: copy, add native UI, verify original files")
    p.add_argument("--staging-only", action="store_true",
                   help="Prepare inspectable native files, do not create an MPQ")
    args = p.parse_args()
    args.output = args.output.resolve()
    if args.output.exists():
        p.error("Output already exists; do not replace an existing client patch")
    if not args.staging_only and not args.mpqcli:
        p.error("--mpqcli is required unless --staging-only is selected")
    if args.toc_archive and not args.mpqcli:
        p.error("--mpqcli is required to read --toc-archive")

    with tempfile.TemporaryDirectory(prefix="af-native-") as work:
        temp = Path(work)
        if args.merge_archive:
            # The highest-priority current patch may itself override FrameXML.toc.
            # Use its version so CoA custom client loader entries are retained.
            existing_names = known_archive_names(args.mpqcli, args.merge_archive)
            if normalize_archive_name(TOC_MEMBER) in existing_names:
                toc = extract_toc(args.mpqcli, args.merge_archive, temp / "toc-current")
            else:
                toc = (args.toc_file.read_bytes() if args.toc_file else
                       extract_toc(args.mpqcli, args.toc_archive, temp / "toc"))
        else:
            toc = (args.toc_file.read_bytes() if args.toc_file else
                   extract_toc(args.mpqcli, args.toc_archive, temp / "toc"))
        payload = temp / "payload"
        report = stage(args.upstream, toc, payload)
        if args.staging_only:
            shutil.copytree(payload, args.output)
            report["mode"] = "staging-only; no client changes"
        else:
            if args.merge_archive:
                report.update(merge_existing_patch(
                    args.mpqcli, args.merge_archive, payload, args.output, temp))
                report["mode"] = "merged and every original MPQ file verified; not installed"
            else:
                run(args.mpqcli, "create", "--game", "wow-wotlk",
                    "--output", args.output, payload)
                verify = temp / "verify"
                run(args.mpqcli, "extract", "--keep", "--output", verify, args.output)
                report["verified_members"] = compare_inventory(payload, verify)
                report["mode"] = "built and readback-verified; not installed"
            report["output_sha256"] = digest(args.output)
        (args.output.parent / (args.output.name + ".json")).write_text(
            json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(report, indent=2))

if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, RuntimeError) as exc:
        print("ERROR:", exc, file=sys.stderr)
        sys.exit(1)
