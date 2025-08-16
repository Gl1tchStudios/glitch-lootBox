# 🎲 Glitch Loot Box System v2.0

A **CSGO-style animated loot box system** for FiveM with exact positioning, rarity tiers, and aggressive mouse release fixes.

## ✨ Features

- **CSGO-Style Spinner Animation** - 60-item spinner with exact winning position
- **6-Tier Rarity System** - Common, Uncommon, Rare, Epic, Legendary, Mythic
- **Dual Mode Support** - Animated UI or classic notifications 
- **Enhanced Mouse Release** - Multiple failsafes to prevent stuck cursor
- **Reward Synchronisation** - Pre-selected rewards ensure animation matches actual item
- **Sound Effects** - Different sounds for each rarity tier
- **Emergency Controls** - ESC/Backspace force close, auto-timeout protection

## 🎨 Rarity System

| Rarity | Color | Weight | Examples |
|--------|--------|---------|----------|
| **Common** | Light Blue | 40% | Bread, Water, Phone |
| **Uncommon** | Green | 25% | Lockpick, Repair Kit, Bandage |
| **Rare** | Blue | 20% | Pistol Ammo, Armour, Drill |
| **Epic** | Purple | 10% | Pistol, Knife, Thermite |
| **Legendary** | Orange | 4% | Rifles, Gold Bar |
| **Mythic** | Red | 1% | RPG, Diamond, Dirty Cash |

## 🚀 Installation

1. **Prerequisites:**
   - `glitch-abstraction` resource running
   - ESX or QB framework

2. **Setup:**
   ```bash
   cd resources
   git clone [your-repo] glitch-lootBox
   ```

3. **Start Resource:**
   ```bash
   ensure glitch-lootBox
   ```

## 🎮 Usage

### Basic Usage
1. Give yourself an ammo crate: `/giveitem ammo_crate 1`
2. Use the item from your inventory
3. Watch the CSGO-style animation
4. Click "Collect Reward" when animation finishes

### Testing Commands
- `/testlootbox` - Test the UI with sample data

### Configuration
Edit `shared/config.lua`:
```lua
Config.useUI = true  -- Set to false for classic mode
```

## 🔧 Technical Details

### File Structure
```
glitch-lootBox/
├── server/server.lua      # Core logic & reward system
├── client/client.lua      # NUI management & mouse release
├── shared/config.lua      # Configuration & loot tables
├── html/
│   ├── index.html         # CSGO-style UI structure
│   ├── style.css          # Rarity colors & animations
│   └── script.js          # Spinner logic & exact positioning
└── fxmanifest.lua         # Resource manifest
```

### Key Systems

#### Reward Synchronisation
- Server pre-selects reward before opening UI
- Spinner animation shows exact item player will receive
- No mismatch between animation and actual reward

#### Mouse Release System
- Multiple `SetNuiFocus(false, false)` calls with delays
- Emergency ESC/Backspace handlers
- Background monitoring for lost NUI focus
- Automatic cleanup on resource stop

#### Exact Positioning
- 60-item spinner with fixed item width (120px)
- Winning item always placed at position 45 (0-indexed 44)
- Calculated final position: `-(44 * 120 - 2400)px`
- Extra spins for dramatic effect

## 🛠️ Troubleshooting

### Mouse Cursor Stuck
1. Press **ESC** or **Backspace** for emergency close
2. Auto-timeout closes UI after 30 seconds
3. Check F8 console for error messages

### Item Mismatch
- System now pre-selects rewards on server
- Animation and actual reward are guaranteed to match

### UI Not Opening
1. Ensure `glitch-abstraction` is running
2. Check server console for framework detection
3. Verify `Config.useUI = true` in config

### Sound Issues
- Sounds are handled client-side
- Different sound for each rarity tier
- Check client console for sound errors

## 🎯 Debug Mode

Enable debug logging in `shared/config.lua`:
```lua
config.debug = true
```

This will show:
- Reward selection process
- UI open/close events
- Mouse release attempts
- Error messages

## 📋 Events

### Server Events
- `glitch-lootBox:collectReward` - Player collects reward
- `glitch-lootBox:rewardCollected` - Confirm successful collection

### Client Events  
- `glitch-lootBox:openUI` - Open CSGO-style UI
- `glitch-lootBox:rewardCollected` - Handle collection result

### NUI Callbacks
- `collectReward` - Collect the displayed reward
- `forceCloseUI` - Emergency UI closure
- `playSound` - Play rarity-based sound

## 🎨 Customisation

### Adding New Items
Edit the `lootTable` in `server/server.lua`:
```lua
{ item = 'new_item', label = 'New Item', rarity = 'rare', weight = 20 }
```

### Changing Rarity Colors
Edit `rarityColors` in `client/client.lua`:
```lua
mythic: '#eb4b4b'  -- Red for mythic items
```

### Custom Sounds
Modify the sound system in `client/client.lua`:
```lua
if data.rarity == 'mythic' then
    soundName = 'MEDAL_UP'
    soundSet = 'HUD_MINI_GAME_SOUNDSET'
end
```

## 🔄 Migration from v1.x

1. **Backup** your old configuration
2. **Update** event names from `lootbox:*` to `glitch-lootBox:*`
3. **Test** with `/testlootbox` command first
4. **Configure** rarity colors and sound preferences

## 🐛 Known Issues

- **Fixed**: Mouse cursor stuck after collection
- **Fixed**: Item mismatch between animation and reward
- **Fixed**: UI not properly closing

## 📞 Support

If you encounter issues:
1. Check F8 console for client errors
2. Check server console for server errors  
3. Ensure `glitch-abstraction` is properly loaded
4. Test with `/testlootbox` command first

---

**Made with ❤️ by Glitch Studios**  
*CSGO-style loot boxes for FiveM*
