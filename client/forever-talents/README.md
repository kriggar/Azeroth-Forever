# Approved Conquest of Azeroth talent-window concept

**Approved target:** The owner's 1536 × 1024 image. The picture is a storyboard of **one four-card specialization picker** followed by **one two-tree talent window** for the chosen specialization, illustrated for Moon Priest, Sentinel, Warden and Moon Guard. It is NOT a three-column talent view, and it has no left navigation bar.

## Native client integration

The source is at client/Interface/FrameXML/ForeverCoATalents.lua. It waits for the actual built-in CoATalentFrame (Ascension_CoATalents), then restyles the existing native specialization cards, real ClassTree, real SpecTree and footer.

The native C_CharacterAdvancement system continues to own prerequisites, points, ranks, reset validation and persistence. The original Save Changes, Search and Change Talents controls remain wired to their client code. This preserves the 21 CoA classes. Unlike the discarded design, there is no fabricated third column or read-only alternative tree.

The four portrait images are cropped directly from the approved user image, not newly improvised. Other classes use their built-in specialization art. The two pane backgrounds currently reuse the client's spec atlas with distinct color grading; exact standalone painted backgrounds still require visual comparison in game.

No player-installed addon: add the new Lua file to Interface/FrameXML/FrameXML.toc inside a separate test MPQ.

## Candidate build instructions

Use a compatible CoA game client, Python 3.11+, Pillow and mpqcli v0.11+ (https://github.com/thegraydot/mpqcli/releases).

1. Save the exact approved concept image as approved-talents.png.
2. Run: python client/forever-talents/generate_art.py approved-talents.png --output client/forever-talents/assets
3. Run: python tools/package_forever_talents_client.py --baseline PATH_TO_CLIENT/Data/patch-Z.MPQ --output PATH_TO_STAGING/patch-Z-forever-talents-candidate.MPQ --mpqcli PATH_TO_MPQCLI --assets client/forever-talents/assets
4. Inspect the generated candidate.MPQ.json report. Test only in a disposable copy of the client, and back up the original patch before any replacement.

Do NOT use patch-B.MPQ as an unexamined substitute for a current patch-Z.MPQ; the active patch may contain other changes. The packaging script never edits the original archive.

## Current verification and limitations

Lua was parsed and exercised against a mocked native frame model locally, including spec cards, real two-tree placement and footer data. It is not a Windows-client or live-server test.

Still required: candidate MPQ build/readback with the tool, real client rendering, comparing a screenshot against the exact concept, all four Starcaller choices, all 21 class layouts, clicking talent icons and tooltips, points/reset/search/save, specialization switching, relog persistence, small-screen UI scale. These cannot be asserted until the Windows game client and server are actually run.

The old feature/approved-forever-talents-window branch contains the rejected three-column prototype and should not be merged.
