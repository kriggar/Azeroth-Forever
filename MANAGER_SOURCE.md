# Azeroth Forever — CoA Server Manager source provenance

- Source: https://github.com/Corfirean/azerothcore-wotlk-coa
- Source branch: `coa-bots`
- Exact source revision: `1c658cab46d5057a8972cebd84c840aa6fbc4a91`
- Distribution/build reference: https://github.com/Corfirean/coa-server-build
- Desktop manager: https://github.com/Corfirean/coa-server-manager

The imported tree replaces the earlier Conquest-of-AzerothCore snapshot.
A backup of the earlier code is preserved in Git branch
`backup/before-coa-manager-source`.

The import must include upstream-tracked files even if excluded by upstream's
`.gitignore`. The source-replacement workflow has a tracked-file recovery
and consistency check for this reason.

This is the Manager-compatible server *core source*, not the Manager's installed
server distribution. The official packaging process integrates additional
modules, game data, database baselines, and signed manifests. Compilation,
client compatibility, and gameplay readiness must be verified separately.

Source files retain their original license notices and authorship.
