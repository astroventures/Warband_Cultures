# Warband Troop Slot System Analysis

## Overview

The Warband Module System uses a slot-based storage mechanism for persistent data attached to game entities (troops, parties, factions, items). This analysis documents how we can use this system for custom unit definitions.

## Slot Operations

### Setting Slots
```python
troop_set_slot, <troop_id>, <slot_no>, <value>  # For troops
party_set_slot, <party_id>, <slot_no>, <value>  # For parties/settlements
faction_set_slot, <faction_id>, <slot_no>, <value>  # For factions
item_set_slot, <item_id>, <slot_no>, <value>  # For items
```

### Getting Slots
```python
troop_get_slot, <destination>, <troop_id>, <slot_no>
party_get_slot, <destination>, <party_id>, <slot_no>
faction_get_slot, <destination>, <faction_id>, <slot_no>
item_get_slot, <destination>, <item_id>, <slot_no>
```

### Slot Conditionals
```python
troop_slot_eq, <troop_id>, <slot_no>, <value>  # Equal
troop_slot_ge, <troop_id>, <slot_no>, <value>  # Greater or equal
party_slot_eq, <party_id>, <slot_no>, <value>
# etc.
```

## Existing Slot Ranges

### Troop Slots (Used by Vanilla)
| Range | Purpose |
|-------|---------|
| 0-9 | Basic state (occupation, party template, etc.) |
| 10-29 | Hero data (wealth, center, age, etc.) |
| 30-40 | Family relations (spouse, parents, etc.) |
| 45-80 | Personality, morality, conflict tracking |
| 85-99 | Custom banner data |
| 101-140 | Conversation strings |
| 141-161 | King support, missions, etc. |
| 165-290 | Lord relations (dynamic array) |

### Party/Settlement Slots (Used by Vanilla)
| Range | Purpose |
|-------|---------|
| 0-50 | Basic town data (lord, scenes, NPCs) |
| 50-100 | Village state, prosperity, sieges |
| 120-160 | Improvements, enterprises, walkers |
| 200-250 | Economic resources (cattle, crops, etc.) |
| 250-350 | Trade goods prices, reconnaissance |

## Custom Slot Allocations (Warband Cultures Mod)

### Troop Slots (300-399)

**Unit Definition (300-309)**
| Slot | Constant | Purpose |
|------|----------|---------|
| 300 | `wc_slot_troop_is_custom` | 1 if player-defined troop |
| 301 | `wc_slot_troop_culture` | Culture faction reference |
| 302 | `wc_slot_troop_tier` | Unit tier (1-5) |
| 303 | `wc_slot_troop_is_mounted` | 1 if cavalry |
| 304 | `wc_slot_troop_base_strength` | STR stat |
| 305 | `wc_slot_troop_base_agility` | AGI stat |
| 306 | `wc_slot_troop_base_intelligence` | INT stat |
| 307 | `wc_slot_troop_base_charisma` | CHA stat |

**Skills (310-329)**
| Slot | Constant | Purpose |
|------|----------|---------|
| 310 | `wc_slot_troop_skill_ironflesh` | Ironflesh skill level |
| 311 | `wc_slot_troop_skill_powerstrike` | Power Strike level |
| 312 | `wc_slot_troop_skill_powerdraw` | Power Draw level |
| ... | ... | Additional combat skills |

**Economics (330-339)**
| Slot | Constant | Purpose |
|------|----------|---------|
| 330 | `wc_slot_troop_total_equip_cost` | Sum of equipment costs |
| 331 | `wc_slot_troop_maintenance_cost` | Weekly upkeep |
| 332 | `wc_slot_troop_upgrade_cost` | Cost to upgrade |

**Upgrade Tree (340-349)**
| Slot | Constant | Purpose |
|------|----------|---------|
| 340 | `wc_slot_troop_upgrades_to_1` | First upgrade path |
| 341 | `wc_slot_troop_upgrades_to_2` | Second upgrade path |
| 342 | `wc_slot_troop_upgrades_from` | Parent troop |

**Equipment (350-387)**
- Armor slots (350-365): Head, Body, Foot, Gloves with 4 variants each
- Weapon loadouts (370-381): 3 loadouts × 4 weapons
- Horse slots (385-387): For mounted units

### Settlement Slots (400-412)

**Culture Percentages (400-409)**
| Slot | Constant | Purpose |
|------|----------|---------|
| 400 | `wc_slot_center_culture_pct_1` | Swadian % |
| 401 | `wc_slot_center_culture_pct_2` | Vaegir % |
| 402 | `wc_slot_center_culture_pct_3` | Khergit % |
| 403 | `wc_slot_center_culture_pct_4` | Nord % |
| 404 | `wc_slot_center_culture_pct_5` | Rhodok % |
| 405 | `wc_slot_center_culture_pct_6` | Sarranid % |
| 406-409 | `wc_slot_center_culture_pct_7-10` | Player cultures |

**Culture Dynamics (410-412)**
| Slot | Constant | Purpose |
|------|----------|---------|
| 410 | `wc_slot_center_culture_shift_rate` | Change speed |
| 411 | `wc_slot_center_last_culture_update` | Last update hour |
| 412 | `wc_slot_center_population_density` | Culture inertia modifier |

## Save Game Persistence

**Slot data persists across saves automatically.** The game engine handles serialization of slot data for:
- Troops defined in `module_troops.py`
- Parties (including settlements) in `module_parties.py`
- Factions in `module_factions.py`

**Important Notes:**
1. Slot values are integers (no floats or strings)
2. Slots are initialized to 0 by default
3. Slot numbers have no theoretical upper limit
4. Performance scales linearly with slot count (keep reasonable)

## Prototype Scripts Created

### `wc_test_troop_slots`
Tests setting/getting custom troop slot data. Demonstrates:
- Setting stats, tier, equipment cost
- Retrieving values for display
- Basic slot CRUD operations

### `wc_test_center_culture_slots`
Tests settlement culture percentage system. Demonstrates:
- Mixed culture percentages (must sum to 100%)
- Slot storage for each culture
- Verification of data integrity

### `wc_weighted_culture_select`
Production-ready weighted random selection. Algorithm:
1. Get all culture percentages for center
2. Roll 0-100
3. Cumulative threshold selection
4. Returns culture index and faction

### `wc_calculate_troop_maintenance`
Economic calculation example:
- Input: troop_id
- Output: weekly maintenance (1% of equipment cost)

## Key Findings

### What Works Well
1. **Unlimited custom slots**: Can define as many as needed
2. **Auto-persistence**: Saves/loads automatically
3. **Fast access**: O(1) lookup by slot number
4. **Type flexibility**: Can store troop IDs, item IDs, values

### Limitations
1. **Integer only**: No floats, use fixed-point (×100 or ×1000)
2. **No arrays**: Must use sequential slot numbers for arrays
3. **No direct strings**: Use string registers or predefined strings
4. **Reserved ranges**: Must avoid vanilla slot conflicts

### Recommendations

1. **Use high slot numbers** (300+) to avoid vanilla conflicts
2. **Group related data** contiguously for clarity
3. **Document all slots** in module_constants.py
4. **Initialize slots** in game_start or on first access
5. **Validate totals** (e.g., culture percentages = 100%)

## Files Modified

| File | Changes |
|------|---------|
| `module_constants.py` | Added wc_slot_troop_* (300-399) and wc_slot_center_culture_* (400-412) |
| `module_scripts.py` | Added 4 test/utility scripts |

## Next Steps

1. Test slot persistence across save/load
2. Create equipment cost calculation script
3. Implement culture shift trigger
4. Build troop definition UI integration
