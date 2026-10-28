# Azeroth Forever — approved three-column talents

The visual target is the user's approved **black-and-gold three-column talent-window concept** with the **Specialization / Talents / Glyphs** sidebar, illustrated tree backgrounds, dependency connections, rank counters and a compact bottom action bar. Arms, Fury and Protection in the reference are example labels, not replacements for the actual 21 Conquest of Azeroth classes.

## Integration

The built-in source is [ForeverTalents.lua](../Interface/FrameXML/ForeverTalents.lua). It extends the existing \`CoATalentFrame\` after its client-side mixins load and keeps the actual \`TalentTreeBase\` controls, native \`C_CharacterAdvancement\` service, talent IDs, tooltips, validation and Apply/Undo/Reset behavior.

The three visible columns use a real **class talent tree** plus **two real specialization talent trees**. Clicking the other specialization pane calls the client-native specialization-switch operation and moves the **editable** specialization tree into the selected pane. Clicking **Next Spec** cycles any additional specializations, including classes with four. The third column is not a permanently read-only or dummy display. The selected specialization can be spent from its selected column.

**Gameplay constraint:** CoA's current server provides one class budget and one *active-specialization* budget. Changing specialization changes the pending active spec; the current client/server do not support simultaneous spending across multiple specialization trees. This integration does not fabricate extra talent currency or bypass the server. A switch is refused while there are unapplied talent edits. A fully independent three-specialization point model would require a separate server/client-DLL migration.

This is an **experimental native UI integration**. The three-column shell is implemented; art fidelity to the supplied concept and in-game acceptance are not yet confirmed. The initial graphics use the installed client's own talent sprites, backgrounds and icon resources.

## Built into the client, not an addon

The player does not install a separate addon. Build a **candidate** MPQ with the repo's existing \`tools/package_hotspot_client.py\` to append \`ForeverTalents.lua\` to the effective \`Interface/FrameXML/FrameXML.toc\`:

\`\`\`sh
python tools/package_hotspot_client.py \
  --baseline /path/to/compatible/client-archive.MPQ \
  --output /path/to/candidate/patch-ForeverTalents.MPQ \
  --mpqcli /path/to/mpqcli \
  --lua ForeverTalents.lua
\`\`\`

The packager refuses an existing output, preserves the baseline, verifies archive contents by readback, and writes an inventory report. It does not modify the user's installed archives, register a launcher manifest or deploy automatically. Keep the old MPQ and client UI backup untouched until the new candidate works in game.

## Acceptance checklist

1. Launch the user's uploaded Ascension/CoA client with a **separate test MPQ**, enable script errors and open talents.
2. Visually compare the three columns, sidebar, frame scale, real class/spec labels, icons, artwork, rank counters and connection graphics against the approved image.
3. Test class-tree and active-specialization point spending, Reset All, Undo, Apply Changes and relog persistence on a real server.
4. Click the inactive specialization column: after switching, its actual talent icons should become editable *in that column*. Verify the pending-change guard and the Next Spec action on a four-specialization class.
5. Test Specialization and Glyphs navigation, low resolution scaling, open/close, and combat/progression restrictions.
6. Run repository verification via \`python -B tools/verify_all.py --stages source --base origin/main\` and relevant gameplay tests where server tools are available.

**Verification status:** Lua syntax inspection is available locally. Actual client rendering, MPQ injection into the supplied client, in-game automation, and server persistence tests have **not** been performed in this environment. Do not treat this draft as a tested production client patch.
