# Display assets

## Current interface previews

The homepages now show the current interface using actual Flutter component renders in [`../design/previews/`](../design/previews/), covering the desktop bookshelf, light/dark mobile bookshelf, notes and settings, with links to desktop settings and reading-history cards. These previews use fictional data and Chinese labels in both language editions. See the [design notes](../design/README.md) for their source, generation command and validation scope.

## Retired feature artwork

The 37 composed phone/Mac showcase images previously stored in `showcase/cross-platform/` have been removed from the current tree and both homepages. They remain available in [Git history](https://github.com/sobranie2406/modureader/tree/a038cc25c17b9a3f1c56588295918d53c3696a1c/docs/images/showcase/cross-platform). These were illustrative artwork based on earlier interfaces, with fictional books, notes and reading data; they are not current component previews or untouched device screenshots.

## Historical source archive

Source images were removed from the current tracked tree on 2026-10-03 to avoid shipping unused, duplicate or upstream marketing material. They remain recoverable in [the previous Git revision](https://github.com/sobranie2406/modureader/tree/dae8ecc4ef7ac34cfe252f8039008716d5cee6ff/docs/images), and local copies are ignored rather than deleted:

- `showcase/*.png`: previous iPhone-only renders used to compose the current artwork.
- `v1.1.9/`: Android and Mac Modu `1.1.9+10063` captures from 2026-10-01, including original demo books/settings.
- Seven older `*-macos.jpg` files: Modu `1.1.1+10033` captures from 2026-09-21, including the then-approved vertical-reading example.
- `Anx-logo.jpg`, `main.jpg`, `wide*.png`, `mobile*.png` and `zh/`: inherited Anx Reader promotional assets, not current Modu UI.

These retired assets retain local copies and Git history for recovery/design work. Do not republish upstream screenshots as current Modu. Dependencies' licenses, copyrights and provenance are outside this asset-cleanup scope.
