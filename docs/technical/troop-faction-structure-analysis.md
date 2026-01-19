# Warband Troop and Faction Structure Analysis

## Overview

This analysis documents the vanilla troop tier system, equipment cost patterns, and upgrade tree structure for use in the dynamic unit creation system.

## Troop Definition Format

```python
["troop_id", "Display Name", "Plural Name", tf_flags, scene, reserved, faction,
 [equipment_list],
 attributes|level(X), weapon_proficiencies, knows_skills, face_code1, face_code2]
```

### Key Fields

| Field | Purpose |
|-------|---------|
| `tf_flags` | Guarantees (armor, boots, helmet, etc.), mounted flag |
| `faction` | Faction ID (fac_kingdom_1, etc.) |
| `equipment_list` | Items the troop can spawn with (random selection) |
| `attributes` | STR, AGI, INT, CHA combined with level |
| `weapon_proficiencies` | wp() function or explicit wp_* values |
| `knows_*` | Skills like ironflesh, power_strike, etc. |

## Tier Patterns (Swadian Infantry Line)

### Tier 1: Recruit (Level 4)
```python
attributes: def_attrib|level(4)  # str_7|agi_5|int_4|cha_4
proficiency: wp(60)
skills: knows_common
equipment: Basic weapons (scythe, club), no armor guarantee
```
- **Estimated Equipment Cost**: ~50-150 denars

### Tier 2: Militia (Level 9)
```python
attributes: def_attrib|level(9)
proficiency: wp(75)
skills: knows_common
equipment: Padded cloth, crossbow, shields
flags: tf_guarantee_boots|tf_guarantee_armor|tf_guarantee_shield
```
- **Estimated Equipment Cost**: ~200-400 denars

### Tier 3: Footman (Level 14)
```python
attributes: def_attrib|level(14)
proficiency: wp_melee(85)
skills: knows_ironflesh_2|knows_shield_2|knows_athletics_2|knows_power_strike_2
equipment: Mail with tunic, helmets, better weapons
```
- **Estimated Equipment Cost**: ~1,000-1,500 denars

### Tier 4: Infantry (Level 20)
```python
attributes: def_attrib|level(20)
proficiency: wp_melee(105)
skills: knows_ironflesh_2|knows_power_strike_2|knows_shield_3|knows_athletics_3|knows_riding_3
equipment: Mail with surcoat, better helmets
flags: tf_guarantee_helmet added
```
- **Estimated Equipment Cost**: ~1,500-2,500 denars

### Tier 5: Sergeant (Level 25)
```python
attributes: def_attrib|level(25)
proficiency: wp_melee(135)
skills: knows_shield_4|knows_ironflesh_4|knows_power_strike_4|knows_athletics_4
equipment: Coat of plates, gauntlets, elite weapons
flags: tf_mounted added
```
- **Estimated Equipment Cost**: ~4,000-6,000 denars

## Default Attributes

```python
def_attrib = str_7 | agi_5 | int_4 | cha_4
```

For specific troops, attributes can be set explicitly:
```python
str_14 | agi_10 | int_4 | cha_4 | level(24)  # Sharpshooter
```

## Weapon Proficiency Patterns

| Function | Description |
|----------|-------------|
| `wp(X)` | All proficiencies at X |
| `wp_melee(X)` | One-handed +20, Polearm +10, Two-handed at X |
| `wpe(m,a,c,t)` | Melee, Archery, Crossbow, Throwing |
| `wpex(o,w,p,a,c,t)` | All 6 proficiencies explicitly |

### Tier to Proficiency Mapping

| Tier | Level | Base Proficiency |
|------|-------|------------------|
| 1 | 4 | 60 |
| 2 | 9 | 75 |
| 3 | 14 | 85-100 |
| 4 | 19-21 | 100-110 |
| 5 | 24-28 | 130-150 |

## Skill Progression

### Combat Skills by Tier

| Skill | Tier 1-2 | Tier 3 | Tier 4 | Tier 5 |
|-------|----------|--------|--------|--------|
| Ironflesh | 0-1 | 2 | 2-3 | 4-5 |
| Power Strike | 0-1 | 2 | 2-3 | 4-5 |
| Shield | 0 | 2 | 3 | 4-5 |
| Athletics | 0 | 2 | 3 | 4 |
| Riding (cav) | 0-2 | 3-4 | 4 | 5 |

## Equipment Cost Reference

### Body Armor (by protection level)

| Armor | Body Armor | Cost (denars) |
|-------|------------|---------------|
| Pelt Coat | 9 | 14 |
| Leather Jerkin | ~15 | ~80 |
| Padded Cloth | ~20 | ~200 |
| Mail with Tunic | ~35 | ~700 |
| Mail Hauberk | 40 | 1,320 |
| Mail with Surcoat | 42 | 1,544 |
| Brigandine | 46 | 1,830 |
| Coat of Plates | 52 | 3,828 |
| Plate Armor | 55 | 6,553 |
| Black Armor | 57 | 9,496 |

### Weapons (by damage)

| Weapon | Damage | Cost (denars) |
|--------|--------|---------------|
| Club | 11 blunt | ~5 |
| Spear | 19 thrust | ~75 |
| One-handed Axe | 32 cut | 87 |
| Bastard Sword | 35 cut | 294 |
| Heavy Bastard Sword | 37 cut | 526 |
| Lance | 26 thrust | 270 |
| Heavy Lance | 26 thrust | 360 |

### Cost-to-Protection Ratio

Approximate formula: `cost ≈ (body_armor²) * 2.9`

| Body Armor | Calculated | Actual |
|------------|------------|--------|
| 10 | 290 | ~100 |
| 20 | 1,160 | ~300 |
| 30 | 2,610 | ~800 |
| 40 | 4,640 | ~1,300 |
| 50 | 7,250 | ~3,000 |
| 55 | 8,782 | ~6,500 |

The formula overestimates low-tier armor but aligns better at high tiers.

## Upgrade Tree Structure

### Format
```python
upgrade(troops, "source_troop", "target_troop")  # Single path
upgrade2(troops, "source", "target_a", "target_b")  # Branch
```

### Swadian Example
```
Recruit (T1)
    └── Militia (T2)
            ├── Footman (T3)
            │       ├── Man at Arms (T4) → Knight (T5)
            │       └── Infantry (T4) → Sergeant (T5)
            └── Skirmisher (T3) → Crossbowman (T4) → Sharpshooter (T5)
```

### Tree Characteristics

- Maximum 2 branches per troop
- Typically branches at Tier 2-3
- Infantry and Cavalry usually split at Tier 3
- Ranged splits from melee at Tier 2

## Faction Differences

### Swadia
- Heavy cavalry focus (knights)
- Crossbow ranged units
- Strong armor progression

### Vaegir
- Horse archer tradition
- Two-handed axe infantry (bardiche)
- Mixed bow/horse units

### Khergit
- Full cavalry faction
- Horse archer specialists
- Light armor, high mobility

### Nord
- Pure infantry focus
- No cavalry line
- Strong archers, throwing weapons

### Rhodok
- Spearmen anti-cavalry
- Crossbow specialists
- Strong defensive units

### Sarranid
- Desert cavalry (Mamlukes)
- Archer tradition
- Balanced infantry/cavalry

## Implications for Custom Unit System

### Stat Point Allocation by Tier

| Tier | Level | Suggested Stat Points | Suggested Skill Points |
|------|-------|----------------------|------------------------|
| 1 | 4 | 16 (STR 7, AGI 5, INT/CHA 4) | 4-6 |
| 2 | 9 | 18 (STR 8, AGI 6) | 8-10 |
| 3 | 14 | 22 (STR 10, AGI 7-8) | 14-16 |
| 4 | 20 | 26 (STR 12, AGI 9) | 20-24 |
| 5 | 25-28 | 30 (STR 14-15, AGI 10-11) | 28-32 |

### Equipment Budget by Tier

| Tier | Min Cost | Max Cost | Average |
|------|----------|----------|---------|
| 1 | 50 | 200 | 125 |
| 2 | 200 | 500 | 350 |
| 3 | 800 | 2,000 | 1,400 |
| 4 | 1,500 | 4,000 | 2,750 |
| 5 | 4,000 | 10,000 | 7,000 |

### Maintenance Formula

Based on equipment cost:
```
weekly_maintenance = equipment_cost / 100
```

| Equipment Cost | Weekly Maintenance |
|----------------|-------------------|
| 125 (T1) | 1 denar |
| 350 (T2) | 4 denars |
| 1,400 (T3) | 14 denars |
| 2,750 (T4) | 28 denars |
| 7,000 (T5) | 70 denars |

### Upgrade Cost Formula

```
upgrade_cost = (new_equipment_cost - old_equipment_cost) + (level_diff * 10)
```

Example: Footman (T3) → Infantry (T4)
- Equipment diff: 2,750 - 1,400 = 1,350
- Level diff: 20 - 14 = 6
- Upgrade cost: 1,350 + 60 = 1,410 denars

## Files Referenced

| File | Data |
|------|------|
| `module_troops.py` | Troop definitions, upgrade trees |
| `module_items.py` | Item costs, stats |
| `module_factions.py` | Culture definitions |
| `header_troops.py` | tf_* flags |
| `header_skills.py` | knows_* constants |
