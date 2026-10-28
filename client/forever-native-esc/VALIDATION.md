# Verification — October 28, 2026

## Passed in this environment

- 13 Python tests using `python -m unittest discover -s tests -p test_*.py`.
- 19 `.lua` files parsed successfully with Lua 5.4 via the system shared library.
- Three focused Lua mock tests passed: `test_native_game_menu.lua`, `test_native_micro_menu.lua`, `test_native_polish.lua`.
- Game Menu: 8 functional rows with available native actions; button anchor/size consistency; one layout owner; Trial and redundant old menu controls hidden; original secure Logout, Quit and Return handlers preserved.
- UI scaling: auto-upgrade old 82% default to 76%; preserve 70% chosen manually; `/afui` command remains.
- UI collision: hide overlapping spellbook search only and preserve unrelated search and native CoA talent UI.
- Native FrameXML loader: untouched CoA lines retained; upstream `GameMenu.lua` skipped; native replacement installed in loader; CoA talent overrides excluded; no new addon folder/GlueXML.

## Unavailable / not validated

- Third-party `mpqcli` and pinned complete ForeverUI art source not available together in runtime; a real MPQ was not generated here.
- Windows PowerShell `.bat` / `.ps1` execution is untested here.
- No native Ascension.exe render, no actual screenshot comparison, no gameplay account login or persistence test.
- Modern 2026 WoW Forever Options/Edit Mode feature parity is limited by the 3.3.5 CoA client's APIs; unsupported settings are intentionally omitted rather than faked.

**Use BUILD ONLY and a disposable test client first. Do not install to the sole working client.**
