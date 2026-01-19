# Warband Recruitment System Analysis

## Overview

The M&B Warband recruitment system uses a culture-based approach where settlements spawn troops based on their assigned culture.

## Key Components

### 1. Culture Factions

Cultures are defined as factions in `module_factions.py`:

```python
("culture_1",  "{!}culture_1", 0, 0.9, [], []),  # Swadian
("culture_2",  "{!}culture_2", 0, 0.9, [], []),  # Vaegir
("culture_3",  "{!}culture_3", 0, 0.9, [], []),  # Khergit
("culture_4",  "{!}culture_4", 0, 0.9, [], []),  # Nord
("culture_5",  "{!}culture_5", 0, 0.9, [], []),  # Rhodok
("culture_6",  "{!}culture_6", 0, 0.9, [], []),  # Sarranid
```

### 2. Culture Tier Troops

Each culture faction has tier troops stored in slots (`module_scripts.py` lines 102-136):

| Slot | Constant | Purpose |
|------|----------|---------|
| 41 | `slot_faction_tier_1_troop` | Basic recruit |
| 42 | `slot_faction_tier_2_troop` | Militia/Footman |
| 43 | `slot_faction_tier_3_troop` | Trained unit |
| 44 | `slot_faction_tier_4_troop` | Veteran |
| 45 | `slot_faction_tier_5_troop` | Elite (Knight, etc.) |

Example for Swadia (culture_1):
```python
(faction_set_slot, "fac_culture_1", slot_faction_tier_1_troop, "trp_swadian_recruit"),
(faction_set_slot, "fac_culture_1", slot_faction_tier_2_troop, "trp_swadian_militia"),
# ... etc
```

### 3. Kingdom-Culture Linkage

Kingdoms reference cultures via `slot_faction_culture` (slot 10):

```python
(faction_set_slot, "fac_kingdom_1", slot_faction_culture, "fac_culture_1"),  # Swadia
(faction_set_slot, "fac_kingdom_2", slot_faction_culture, "fac_culture_2"),  # Vaegirs
# ... etc
```

### 4. Settlement Culture

Settlements (centers) store their culture in `slot_center_culture` (slot 19):

```python
# At game initialization (module_scripts.py line 601-604):
(try_for_range, ":center_no", centers_begin, centers_end),
    (store_faction_of_party, ":original_faction", ":center_no"),
    (faction_get_slot, ":culture", ":original_faction", slot_faction_culture),
    (party_set_slot, ":center_no", slot_center_culture, ":culture"),
```

### 5. Recruitment Script Flow

Script `update_volunteer_troops_in_village` (line ~31876):

```
1. Get settlement's culture from slot_center_culture
2. Get tier 1 troop from that culture's slot_faction_tier_1_troop
3. Check player relation with settlement
4. Higher relation = chance for higher tier troops (10 relation = +10% chance)
5. Store result in slot_center_volunteer_troop_type
```

## Key Slot Constants

```python
# module_constants.py
slot_faction_culture = 10           # Faction's culture reference
slot_center_culture = 19            # Settlement's culture
slot_center_volunteer_troop_type = 92   # Current recruit type
slot_center_volunteer_troop_amount = 93 # Current recruit count

slot_faction_tier_1_troop = 41
slot_faction_tier_2_troop = 42
slot_faction_tier_3_troop = 43
slot_faction_tier_4_troop = 44
slot_faction_tier_5_troop = 45
```

## Implications for Dynamic Culture Mod

### What We Can Leverage

1. **Settlement slots**: Use additional slots for multi-culture percentages
2. **Recruitment scripts**: Override `update_volunteer_troops_in_village` to use weighted random
3. **Trigger system**: Add daily/weekly triggers for culture shift calculations
4. **Culture factions**: Can define new culture factions for custom cultures

### Proposed Slot Schema for Dynamic Culture

```python
# New slots for settlement culture percentages (use slots 400-410)
slot_center_culture_pct_1 = 400  # % of culture 1 (0-100)
slot_center_culture_pct_2 = 401  # % of culture 2
slot_center_culture_pct_3 = 402  # etc...
slot_center_culture_pct_7 = 406  # For player custom culture

# Total should always = 100
```

### Modified Recruitment Flow

```
1. Get all culture percentages from settlement slots
2. Generate random 0-100
3. Select culture based on cumulative percentage thresholds
4. Get tier troop from selected culture
5. Apply squared scaling: if culture_pct = 40%, spawn_chance = 16%
```

## Files to Modify

| File | Changes |
|------|---------|
| `module_constants.py` | Add new slot constants |
| `module_scripts.py` | Override recruitment scripts, add culture update scripts |
| `module_simple_triggers.py` | Add periodic culture update trigger |
| `module_factions.py` | Add player custom culture faction(s) |
| `module_game_menus.py` | Add culture display to settlement info |
