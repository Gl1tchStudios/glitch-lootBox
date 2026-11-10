# Changelog

## 3.1.2

- `config/crates.lua` now ships three crates that use stock ox_inventory items only. The larger demo set moved to `config/crates.demo.lua`, picked with `config.server.cratePack`. `pawnCheck` is off by default, ox_lib is declared as a dependency, and tokens are seeded once at start.

## 3.1.1

- Roll is saved before the crate is taken, pending loot is only cleared after it is handed over, a grant checks the character still matches, tokens are random, and crates with no usable reward are skipped at start.

## 3.1.0

- Rolled loot is written to the resource KVP store when the crate is taken and removed once it is in the inventory. A disconnect, character switch or server crash mid-spin no longer loses it. It is handed over the next time that character loads in.
- Crates now live in `config/crates.lua` (server only, so clients no longer download the loot tables). Server settings are in `config/server.lua`.
- All player-facing text moved to `locales/en.lua`, and the crate screen reads its strings from there.
- Icons default to the ox_inventory image folder. The CDN overrides are gone and `ui.inventory.iconOverrides` is empty.
- The Barlow fonts are bundled, so nothing loads from the internet.
- Open Another only works for the crate that just finished, and dead, last stand or cuffed players cannot open crates.
- A crate whose rewards are all restricted to other job sources refuses to roll instead of picking one at random.
- Blueprint rewards are left out of the roll and the preview while glitch-crafting is not running.
- The NUI config is sent once per session, not with every message.
- glitch-abstraction is optional. The pawn check for glitch-criminaltablet sits behind `config.integrations`.
- `install/items.lua`, LICENSE and CHANGELOG added. The demo GIF moved to `docs/`.

## 3.0.0

First release of the case opening screen.
