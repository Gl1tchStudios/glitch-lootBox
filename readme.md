<h1 align="center">glitch-lootBox</h1>

<h3 align="center">CS2 case opening, for your FiveM server.</h3>

<p align="center">
  <b>Use a crate, see what is inside, then watch the reel spin and land on your reward.</b><br>
  Every roll is decided by the server, so what the reel shows is what the player gets.
</p>

<p align="center">
  Free and open source. Works with Qbox, QBCore or ESX, best with ox_inventory.
</p>

<p align="center">
  <a href="../../archive/refs/heads/main.zip"><img src="https://img.shields.io/badge/DOWNLOAD-GLITCH--LOOTBOX.ZIP-1f6feb?style=for-the-badge&labelColor=555555" alt="Download glitch-lootBox"></a>
</p>

<img width="800" height="450" alt="demo" src="https://github.com/user-attachments/assets/eb44a325-c00e-4583-af3e-9515e2f1d155" />

<p align="center">
  FiveM, Qbox / QBCore / ESX &middot; <a href="#install">Install</a> &middot; <a href="#config">Config</a> &middot; <a href="#adding-a-crate">Adding a crate</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/FiveM-resource-f40552" alt="FiveM resource">
  <img src="https://img.shields.io/badge/Lua-5.4-000080" alt="Lua 5.4">
  <img src="https://img.shields.io/badge/framework-Qbox%20%7C%20QBCore%20%7C%20ESX-success" alt="Qbox, QBCore, ESX">
  <img src="https://img.shields.io/badge/version-3.0.0-blue" alt="Version 3.0.0">
</p>

Use it for ammo crates, heist loot, event rewards or anything else that should feel good to open.

## How it looks

1. **Unlock Container** - the case, everything it can contain with grade colours and drop odds, any guaranteed extras, and how many the player has.
2. **Reel** - a strip of cards weighted like the real odds spins under a gold marker, ticking on every card, then slows to a long crawl and stops at a random point inside the winning card.
3. **Reveal** - the item with a burst in its rarity colour, sparkles from Epic up, the extras that came with it, and **Open Another** if the player has more of the same crate.

Grades marked `mystery` (Mythic by default) show as a gold star "Rare Special Item" card until they are revealed.

## Install

1. Download the resource and put the folder in your resources. Name the folder `glitch-lootBox`.
2. Add each crate to your inventory as a normal item. For ox_inventory, in `data/items.lua`:

```lua
['ammocratet1'] = {
    label = 'Ammo Crate T1',
    weight = 2000,
    stack = true,
    close = true,
},
```

Do not give the crate a `client.export` or `server.export`. The crate is used through your framework.

3. Add `ensure glitch-lootBox` to your server.cfg, after your framework and inventory.

No hard dependencies. glitch-abstraction is used for notifications and non-ox inventories when it is running.

## Config

Settings are in `shared/config.lua`.

| Option | Default | What it does |
| --- | --- | --- |
| `debug` | `false` | Prints every roll and payout to the server console. |
| `useUI` | `true` | `false` opens crates instantly with a notification instead of the UI. |
| `ui.showPreview` | `true` | Shows the Unlock Container screen first. `false` goes straight to the reel. |
| `ui.showChances` | `true` | Shows drop odds on the preview screen. |
| `ui.spinTime` | `6.5` | Seconds the reel spins before it stops. |
| `ui.reelLength` | `56` | Cards on the reel. |
| `ui.winnerIndex` | `48` | Card the reel lands on. Keep it at least 4 below `reelLength`. |
| `ui.allowSkip` | `true` | SPACE or ESC skips straight to the reveal. |
| `ui.volume` | `0.5` | Reel tick volume. `0` mutes it. The reveal uses GTA sounds. |
| `ui.blurBackground` | `true` | Blurs the game behind the UI. |
| `ui.inventory.iconPath` | ox_inventory images | Where item images are loaded from. |

### Rarities

Each grade in `config.rarities` has a `label`, a `color`, an `order` (higher is rarer, 5 and up get sparkles) and a GTA frontend `sound` played on the reveal. Add `mystery = true` to hide that grade behind a gold star card.

The default grades are Common, Uncommon, Rare, Very Rare, Epic, Legendary and Mythic, in the CS2 colours.

## Adding a crate

Add an entry to `config.lootBoxes`. The key is the crate's item name.

```lua
ammocratet1 = {
    name = 'Ammo Crate T1',
    accent = '#b0c3d9', -- colour of the case art (optional)
    rewards = {
        { item = 'ammo-9', label = '9mm Ammo', min = 50, max = 150, rarity = 'common', chance = 40 },
        { item = 'ammo-50', label = '.50 Cal Ammo', min = 50, max = 150, rarity = 'uncommon', chance = 40 },
        { item = 'ammo-shotgun', label = 'Shotgun Shells', min = 15, max = 35, rarity = 'rare', chance = 20 },
    },
    bonusItems = {
        { item = 'money', amount = { min = 25, max = 100 }, label = 'Cash Find' },
    },
},
```

| Field | What it does |
| --- | --- |
| `rewards` | Exactly one is rolled. `chance` is a weight, so they do not need to add up to 100 and decimals are fine. |
| `min` / `max` | Amount range for the reward. |
| `bonusItems` | Always given on top of the reward. `amount` is a number or `{ min, max }`. |
| `accent` | Colour of the drawn case on the preview screen. |
| `image` | An image url to show instead of the drawn case. |
| `label` | Optional. Falls back to the inventory item label. |

### Heist caches

Crates handed out by [glitch-crafting](../glitch-crafting) can use three extra reward fields:

| Field | What it does |
| --- | --- |
| `blueprint` | A glitch-crafting recipe id. The reward becomes a `crafting_blueprint` item for that recipe. `unlock` works the same for glitch-crafting unlocks. |
| `sources` | `{ jobId = true }`. The reward only exists in crates that came from those jobs. |
| `weights` | `{ jobId = 2.0 }`. Multiplies the reward's chance for crates from that job. |

## Controls

| Screen | SPACE / ENTER | ESC / BACKSPACE |
| --- | --- | --- |
| Preview | Unlock | Close |
| Reel | Skip | Skip |
| Reveal | Open Another, or close | Close |

## How it works

- The crate is taken and the reward is rolled on the server when the player presses Unlock. The client only ever sends back a session token, so it cannot choose or change the reward.
- The reward goes into the inventory at the reveal, so the inventory's "item added" popup does not spoil it.
- A rolled crate always pays out exactly once. If the reveal never reports back because the player closed the UI, crashed or disconnected, the server pays out anyway.
- Before a crate is taken, the player must have room for every possible reward, so a full inventory cannot be used to filter out bad rolls. Anything that still does not fit is dropped at their feet (ox_inventory).
- Closing on the preview screen costs nothing. A crate that is already spinning can only be skipped.

## Good to know

- Crates are registered as usable items through qbx_core, qb-core or ESX, in that order, with glitch-abstraction as the last fallback.
- On start the server warns in the console about unknown rarities and crate or reward items that do not exist in ox_inventory.
- Nothing runs while the UI is closed.
