# Azeroth Forever

Source baseline: [Corfirean/azerothcore-wotlk-coa](https://github.com/Corfirean/azerothcore-wotlk-coa), branch `coa-bots`, which is the server-core fork used by the [CoA Server Manager build pipeline](https://github.com/Corfirean/coa-server-build).

The project's direction is the full Conquest of Azeroth class roster with a slower, meaningful, original-Azeroth 1–60 experience. Azeroth Forever is a separate development project, not an official Conquest of Azeroth release.

See [the exact upstream source revision](MANAGER_SOURCE.md).

## What is in this repository?

The **open-source server core**, game scripts, database changes, module sources, and development files. This repository does **not** contain a preinstalled Windows desktop application, a running server, the Manager's official signed releases, or the proprietary WoW/CoA game client data.

The Manager's published build includes additional independent modules (playerbots, content scaling, SQUID) and a signed base package containing client-extracted data. Those must be handled separately; core code alone is not identical to the prebuilt package.

- [Download the CoA Server Manager for Windows](https://github.com/Corfirean/coa-server-manager/releases/latest)
- [Official Manager-compatible server package pipeline](https://github.com/Corfirean/coa-server-build)
- [Azeroth Forever GitHub Actions](https://github.com/kriggar/Azeroth-Forever/actions)

## Licensing

Preserve the upstream license and individual file notices. Client-extracted game assets and proprietary data are not covered by the public source license and must not be committed here.
