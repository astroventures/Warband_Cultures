# Detailed Design: Epics 2-5
## Planning Gate 1 Output

> **Generated:** 2026-01-19
> **Based on:** Epic 1 Technical Discoveries
> **Status:** Ready for Implementation

---

## Summary of Epic 1 Discoveries

### Technical Capabilities Validated

| System | Finding | Impact |
|--------|---------|--------|
| **Presentation System** | Sliders, combos, buttons, text all work | Full UI feasible |
| **Slot System** | Persists across saves, unlimited range | Data storage ready |
| **Troop Patterns** | Clear tier progression (L4→9→14→20→25) | Stat formulas defined |
| **Recruitment** | Culture-based via `slot_center_culture` | Can extend to multi-culture |

### Slot Schema (Established)

- **Troop slots 300-399**: Unit definitions, skills, equipment, upgrades
- **Settlement slots 400-412**: Culture percentages and dynamics

### Key Patterns

- Equipment cost scales ~quadratically with protection
- Skills cap at ~5 for tier 5 troops
- Vanilla uses `wp()` / `wp_melee()` for proficiency shortcuts
- Cultures are factions; recruitment uses `slot_faction_tier_X_troop`

---

# Epic 2: Dynamic Culture System

## Objective
Settlement cultures evolve based on faction control, proximity to cultural centers, and population density.

## Design Decisions

### Culture Representation
- **6 vanilla cultures** + **4 player culture slots** = 10 culture slots per settlement
- Culture percentages stored in slots 400-409 (already defined)
- Percentages must always sum to 100

### Influence Algorithm

```
daily_influence = base_control_rate + proximity_bonus

where:
  base_control_rate = 2% per day if owning faction culture
  proximity_bonus = sum(culture_pct_of_neighbor / distance) for each adjacent settlement

culture_shift:
  owning_culture += daily_influence
  other_cultures -= proportionally
  clamp to 0-100, normalize to sum=100
```

### Recruitment Probability

Per user requirement: squared scaling
```
spawn_probability(culture) = (culture_pct / 100)^2

Example: 40% culture = 16% spawn chance
         70% culture = 49% spawn chance
```

## Detailed Tasks

### Task 2.1: Culture Initialization Script
**File:** `module_scripts.py`
**Script:** `wc_initialize_settlement_cultures`

```python
# For each settlement:
# 1. Get owning faction's culture
# 2. Set that culture to 100%, others to 0%
# Called at game_start and when settlements change hands
```

**Outputs:** Script that initializes all settlement culture slots

---

### Task 2.2: Culture Shift Calculation Script
**File:** `module_scripts.py`
**Script:** `wc_calculate_culture_shift`

```python
# Input: settlement_id
# 1. Get owning faction's culture index
# 2. Calculate base influence (2% toward owning culture)
# 3. Calculate proximity bonus from neighbors
# 4. Apply shift, clamp, normalize
# 5. Store updated percentages
```

**Algorithm Details:**
- Neighbor distance: Use `store_distance_to_party_from_party`
- Influence falloff: 1/distance (max 5% bonus per neighbor)
- Population density modifier: slot 412 scales shift rate

**Outputs:** Script that calculates and applies daily culture shift

---

### Task 2.3: Daily Culture Update Trigger
**File:** `module_simple_triggers.py`
**Trigger:** `wc_trigger_daily_culture_update`

```python
(24, [  # Every 24 hours
    (try_for_range, ":center", centers_begin, centers_end),
        (call_script, "script_wc_calculate_culture_shift", ":center"),
    (try_end),
]),
```

**Outputs:** Simple trigger that iterates all settlements daily

---

### Task 2.4: Weighted Recruitment Selection
**File:** `module_scripts.py`
**Modify:** `script_update_volunteer_troops_in_village`

```python
# Replace single-culture logic with:
# 1. Call wc_weighted_culture_select (already created in Epic 1)
# 2. Get tier troop from selected culture
# 3. Apply squared probability for actual spawn
```

**Note:** `wc_weighted_culture_select` already implemented - needs integration only

**Outputs:** Modified recruitment to use culture percentages

---

### Task 2.5: Culture Display in Settlement Info
**File:** `module_game_menus.py`
**Location:** Settlement info screen

```python
# Add after existing settlement info:
# "Settlement Culture:"
# "  Swadian: {reg0}%"
# "  Vaegir: {reg1}%"
# etc. (only show cultures > 0%)
```

**Outputs:** UI showing culture breakdown in settlement menu

---

### Task 2.6: Faction Change Handler
**File:** `module_scripts.py`
**Script:** `wc_on_settlement_captured`

```python
# Hook into settlement capture event
# 1. Get new owner's culture
# 2. Add 20% instant culture boost to new owner
# 3. Reduce other cultures proportionally
```

**Outputs:** Immediate culture impact when settlements change hands

---

## Epic 2 Deliverables Summary

| Task | Script/File | Purpose |
|------|-------------|---------|
| 2.1 | `wc_initialize_settlement_cultures` | Set initial 100% culture |
| 2.2 | `wc_calculate_culture_shift` | Daily influence algorithm |
| 2.3 | Simple trigger | 24h update cycle |
| 2.4 | Modify recruitment | Use weighted selection |
| 2.5 | Game menu | Display culture % |
| 2.6 | `wc_on_settlement_captured` | Instant capture bonus |

---

# Epic 3: Custom Unit Tree Builder

## Objective
Players build custom troop trees through the upgrade flow, selecting stats, skills, and equipment.

## Design Decisions

### Template Troop Pool
- **100 template troops** in `module_troops.py`
- Named `wc_template_001` through `wc_template_100`
- Allocated 10 per potential player culture (supports 10 cultures)
- All defined with placeholder stats; actual values in slots

### Troop Slot Schema (Updated Planning Gate 2)

```
Unit Definition (300-309):
  300: is_custom (1/0)
  301: culture_faction_id
  302: tier (1-5)
  303: is_mounted (1/0)
  304-307: STR, AGI, INT, CHA

Skills (310-329):
  310: ironflesh, 311: power_strike, 312: power_draw
  313: power_throw, 314: riding, 315: athletics
  316: shield, 317: weapon_master, 318: horse_archery

Economics (330-339):
  330: total_equip_cost
  331: maintenance_cost
  332: upgrade_cost

Upgrade Tree (340-349):
  340: upgrades_to_1
  341: upgrades_to_2
  342: upgrades_from
  343: fork_count (0, 1, or 2)
  344: tree_fork_total (tracks forks in entire tree)
  345: tree_root (reference to tier 1 unit)
  346: tree_depth (tiers from root)

Equipment (350-387):
  Head: 350-353 (4 options)
  Body: 354-357 (4 options)
  Foot: 358-361 (4 options)
  Hand: 362-365 (4 options)
  Loadout 1: 370-373 (4 weapons)
  Loadout 2: 374-377 (4 weapons)
  Loadout 3: 378-381 (4 weapons)
  Horse: 385-387 (3 options, mounted units only)

Proficiencies (390-395):
  390: one_handed, 391: two_handed, 392: polearm
  393: archery, 394: crossbow, 395: throwing

Display/Config (396-399):
  396: display_name_string_id
  397: name_type (Recruit/Footman/Knight etc.)
  398: is_configured (1 if fully set up)
  399: variant_mask (equipment selection bitmask)
```

### Faction Slots for Template Tracking

```
Faction Slots (200-211):
  200: template_next_idx (0-9, next available slot)
  201: template_count (templates used)
  202-206: custom_tier_1-5_troop (root of each tier)
  207: tree_fork_total (total forks in culture tree)
  208: unit_tree_configured (1 if tree defined)
  209: name_string (culture name)
  210: title_king (ruler title)
  211: title_lord (vassal title)
```

### Template Allocation Ranges

| Culture | Templates | Range |
|---------|-----------|-------|
| Swadian (1) | 10 | 0-9 |
| Vaegir (2) | 10 | 10-19 |
| Khergit (3) | 10 | 20-29 |
| Nord (4) | 10 | 30-39 |
| Rhodok (5) | 10 | 40-49 |
| Sarranid (6) | 10 | 50-59 |
| Player 1 (7) | 10 | 60-69 |
| Player 2 (8) | 10 | 70-79 |
| Player 3 (9) | 10 | 80-89 |
| Player 4 (10) | 10 | 90-99 |

### Tier Constraints

| Tier | Level | Stat Points | Skill Points | Max Skills | Prof Base |
|------|-------|-------------|--------------|------------|-----------|
| 1 | 4 | 16 | 6 | 2 | 60 |
| 2 | 9 | 20 | 10 | 4 | 75 |
| 3 | 14 | 24 | 16 | 6 | 90 |
| 4 | 20 | 28 | 24 | 8 | 110 |
| 5 | 26 | 32 | 32 | 10 | 135 |

### Fork Constraints
- Max 2 upgrade paths per troop
- Max 4 forks per tree (tracked in slot 344)
- Fork creates 2 new template troops

## Detailed Tasks

### Task 3.1: Define Template Troops
**File:** `module_troops.py`

```python
# Add 100 template troops at end of troop list
# ("wc_template_001", "Custom Unit", "Custom Units",
#   tf_guarantee_boots|tf_guarantee_armor,
#   no_scene, reserved, fac_commoners,
#   [], str_7|agi_5|int_4|cha_4|level(1), wp(60), knows_common, ...),
```

**Note:** Actual stats/equipment loaded from slots at runtime

**Outputs:** 100 template troop definitions

---

### Task 3.2: Template Allocation System
**File:** `module_scripts.py`
**Script:** `wc_allocate_template_troop`

```python
# Input: culture_faction_id
# 1. Find first unused template in culture's allocation range
# 2. Mark as allocated (set slot 300 = 1)
# 3. Return template troop_id
# 4. Return -1 if pool exhausted
```

**Allocation Ranges:**
- Culture 1 (Swadian): templates 1-10
- Culture 2 (Vaegir): templates 11-20
- ... etc.
- Player cultures 7-10: templates 61-100

**Outputs:** Script that manages template pool

---

### Task 3.3: Unit Creation Presentation
**File:** `module_presentations.py`
**Presentation:** `wc_unit_creator`

**UI Layout (1000x750 virtual):**
```
+--------------------------------------------------+
| [Title: Create Unit - Tier X]                    |
+--------------------------------------------------+
|  [Mounted/Foot Toggle]     [Points: XX]          |
+--------------------------------------------------+
| STATS                    | SKILLS                |
|   STR: [---slider---]    |   Ironflesh [0-5]    |
|   AGI: [---slider---]    |   Power Strike [0-5] |
|   INT: [---slider---]    |   Athletics [0-5]    |
|   CHA: [---slider---]    |   Riding [0-5]       |
|                          |   (more...)          |
+--------------------------------------------------+
| PROFICIENCIES            |
|   One-Handed: [slider]   Two-Handed: [slider]   |
|   Polearm: [slider]      Archery: [slider]      |
+--------------------------------------------------+
| EQUIPMENT                                        |
|   [Head] [Body] [Foot] [Hand]                   |
|   [Loadout 1] [Loadout 2] [Loadout 3]          |
|   [Horse] (if mounted)                          |
+--------------------------------------------------+
| [Confirm]  [Cancel]                              |
+--------------------------------------------------+
```

**Events:**
- Stat changes update available skill points
- Equipment changes update cost display
- Validate constraints before confirm

**Outputs:** Full unit creation UI presentation

---

### Task 3.4: Equipment Browser Presentation
**File:** `module_presentations.py`
**Presentation:** `wc_equipment_browser`

```python
# Input: equipment_slot_type (head, body, weapon, etc.)
# Input: tier_level, stat_requirements
#
# Display: Scrollable list of valid items
# Filter: By stat requirements (STR for heavy armor, etc.)
# Filter: By cost (max based on tier budget)
#
# Return: Selected item_id stored in temp slot
```

**Outputs:** Filtered equipment selection UI

---

### Task 3.5: Loadout Builder Presentation
**File:** `module_presentations.py`
**Presentation:** `wc_loadout_builder`

```python
# Display weapon groups:
# - Sword & Shield (1h sword + shield)
# - Polearm Kit (spear + backup sword)
# - Archer Kit (bow + arrows + sidearm)
# - etc.
#
# Player selects 1-3 loadouts
# System populates weapon slots automatically
```

**Outputs:** Grouped weapon selection UI

---

### Task 3.6: Stat/Skill Validation Scripts
**File:** `module_scripts.py`

```python
# wc_validate_stat_allocation
# - Check total points = tier allocation
# - Check individual stat max (15 for tier 5)
# - Return valid/invalid

# wc_validate_skill_allocation
# - Check total skill points = tier allocation
# - Check individual skill max (5)
# - Check stat requirements (e.g., riding needs AGI 5+)
# - Return valid/invalid
```

**Outputs:** Validation scripts for unit creation

---

### Task 3.7: Apply Unit Configuration Script
**File:** `module_scripts.py`
**Script:** `wc_apply_unit_configuration`

```python
# Input: template_troop_id
#
# 1. Read all slots (stats, skills, equipment)
# 2. Use troop_raise_attribute to set STR/AGI/INT/CHA
# 3. Use troop_raise_skill to set skills
# 4. Use troop_raise_proficiency_* for weapon skills
# 5. Use troop_add_items for equipment
# 6. Calculate and store equipment cost
```

**Note:** Called when unit is first used or configuration changes

**Outputs:** Script that materializes slot data into troop

---

### Task 3.8: Upgrade Flow Integration
**File:** `module_scripts.py`, `module_game_menus.py`
**Scripts:** `wc_check_upgrade_available`, `wc_perform_custom_upgrade`

#### Understanding Vanilla Upgrade System

Vanilla upgrades use compile-time `upgrade()` and `upgrade2()` functions that modify the troop tuple.
The engine calls `troop_get_upgrade_troop` to get upgrade paths.

**Key insight:** Template troops will have NO compile-time upgrades defined. Instead:
1. Engine reports no upgrades available → vanilla behavior
2. We intercept via party screen menu option or custom trigger
3. Check slot 340/341 for runtime-defined upgrades
4. If not defined AND tier < 5: open unit creator
5. If defined: perform upgrade normally

#### Integration Approach

```python
# Script: wc_check_upgrade_available
# Input: troop_id
# Returns: reg0 = 1 if upgrade available, 0 if none defined and can create
#          reg1 = upgrade_to_1 troop_id (or 0)
#          reg2 = upgrade_to_2 troop_id (or 0)

("wc_check_upgrade_available",
 [
   (store_script_param_1, ":troop"),
   # Check if custom troop
   (troop_get_slot, ":is_custom", ":troop", wc_slot_troop_is_custom),
   (try_begin),
     (eq, ":is_custom", 1),
     # Check slot-defined upgrades
     (troop_get_slot, reg1, ":troop", wc_slot_troop_upgrades_to_1),
     (troop_get_slot, reg2, ":troop", wc_slot_troop_upgrades_to_2),
     (try_begin),
       (this_or_next|gt, reg1, 0),
       (gt, reg2, 0),
       (assign, reg0, 1),  # Has defined upgrades
     (else_try),
       (troop_get_slot, ":tier", ":troop", wc_slot_troop_tier),
       (lt, ":tier", 5),
       (assign, reg0, 0),  # Can create new upgrade
     (else_try),
       (assign, reg0, -1),  # Max tier, no upgrades possible
     (try_end),
   (else_try),
     (assign, reg0, -1),  # Not a custom troop
   (try_end),
 ]),

# Script: wc_perform_custom_upgrade
# Called from upgrade menu option
# Input: source_troop, player party_id, stack_no
# Opens unit creator if no upgrade defined, else performs upgrade

("wc_perform_custom_upgrade",
 [
   (store_script_param_1, ":source_troop"),
   (store_script_param_2, ":party"),
   (store_script_param_3, ":stack"),

   (call_script, "script_wc_check_upgrade_available", ":source_troop"),
   (try_begin),
     (eq, reg0, 0),
     # No upgrades defined - open unit creator
     (assign, "$wc_upgrade_source_troop", ":source_troop"),
     (assign, "$wc_upgrade_party", ":party"),
     (assign, "$wc_upgrade_stack", ":stack"),
     (start_presentation, "prsnt_wc_unit_creator"),
   (else_try),
     (eq, reg0, 1),
     # Has upgrade - show selection if fork, else auto-upgrade
     (try_begin),
       (gt, reg1, 0),
       (gt, reg2, 0),
       # Fork - show selection
       (start_presentation, "prsnt_wc_upgrade_select"),
     (else_try),
       # Single path - auto upgrade
       (try_begin),
         (gt, reg1, 0),
         (assign, ":target", reg1),
       (else_try),
         (assign, ":target", reg2),
       (try_end),
       (party_upgrade_troop, ":party", ":source_troop", ":target", 1),
     (try_end),
   (try_end),
 ]),
```

#### Fork Propagation Logic

When creating a new upgrade path:
```python
# 1. Get parent's tree_fork_total
# 2. If parent has fork_count > 0, increment tree_fork_total
# 3. Check against wc_max_forks_per_tree (4)
# 4. Propagate tree_fork_total to new unit
# 5. Set new unit's tree_root = parent's tree_root

("wc_propagate_fork_count",
 [
   (store_script_param_1, ":new_troop"),
   (store_script_param_2, ":parent_troop"),

   # Get parent's tree data
   (troop_get_slot, ":tree_forks", ":parent_troop", wc_slot_troop_tree_fork_total),
   (troop_get_slot, ":tree_root", ":parent_troop", wc_slot_troop_tree_root),
   (troop_get_slot, ":parent_depth", ":parent_troop", wc_slot_troop_tree_depth),

   # If parent has 2 upgrade paths, this is a fork
   (troop_get_slot, ":parent_forks", ":parent_troop", wc_slot_troop_fork_count),
   (try_begin),
     (ge, ":parent_forks", 2),
     (val_add, ":tree_forks", 1),
   (try_end),

   # Set new unit's tree data
   (troop_set_slot, ":new_troop", wc_slot_troop_tree_fork_total, ":tree_forks"),
   (troop_set_slot, ":new_troop", wc_slot_troop_tree_root, ":tree_root"),
   (store_add, ":new_depth", ":parent_depth", 1),
   (troop_set_slot, ":new_troop", wc_slot_troop_tree_depth, ":new_depth"),
   (troop_set_slot, ":new_troop", wc_slot_troop_upgrades_from, ":parent_troop"),
 ]),
```

#### Game Menu Integration

Add "Upgrade Custom Unit" option to party screen:
```python
# In module_game_menus.py, add to party menu:
("wc_upgrade_custom",
 [(store_script_param_1, ":troop"),
  (call_script, "script_wc_check_upgrade_available", ":troop"),
  (ge, reg0, 0),  # Show if has upgrade or can create
 ],
 "Upgrade unit...",
 [(call_script, "script_wc_perform_custom_upgrade", "$wc_selected_troop", "p_main_party", 0),
 ]),
```

**Outputs:** Full integration with upgrade system

---

### Task 3.9: Display Name System
**File:** `module_scripts.py`, `module_strings.py`

```python
# Pre-define string templates:
# str_wc_unit_name_pattern = "{s0} {s1}"  # e.g., "Swadian Footman"
#
# Script wc_generate_unit_name:
# - Culture prefix (Swadian, Vaegir, custom...)
# - Type suffix (Recruit, Footman, Knight, Archer...)
# - Store in string register for display
```

**Outputs:** Dynamic unit naming system

---

## Epic 3 Deliverables Summary

| Task | Component | Purpose |
|------|-----------|---------|
| 3.1 | 100 template troops | Troop pool |
| 3.2 | Allocation script | Manage pool |
| 3.3 | Unit creator UI | Stats/skills selection |
| 3.4 | Equipment browser | Item selection |
| 3.5 | Loadout builder | Weapon groups |
| 3.6 | Validation scripts | Constraint enforcement |
| 3.7 | Apply config script | Materialize unit |
| 3.8 | Upgrade integration | Trigger creation flow |
| 3.9 | Naming system | Dynamic display names |

---

# Epic 4: Economic System

## Objective
Equipment determines costs. Players manage upgrade investments and maintenance.

## Design Decisions

### Cost Formulas (From Epic 1 Analysis)

**Upgrade Cost:**
```
upgrade_cost = (new_avg_equip_cost - old_avg_equip_cost) + (level_diff * 10)
```

**Maintenance Cost (Weekly):**
```
maintenance = total_equip_cost / 100
```

**Modification Delta:**
```
delta = abs(new_equip_cost - old_equip_cost)
charge/refund = delta * unit_count
```

### Vassal System

- Player can toggle "cover vassal costs" option
- When enabled: player pays vassal troop upgrades
- Sentiment bonus: +1 relation per 1000 denars covered
- Sentiment penalty: -1 relation per week vassals pay themselves

## Detailed Tasks

### Task 4.1: Equipment Cost Calculator
**File:** `module_scripts.py`
**Script:** `wc_calculate_equipment_cost`

```python
# Input: troop_id
# 1. Sum item costs from all equipment slots
# 2. For slots with multiple options, use average
# 3. Store in slot 330 (wc_slot_troop_total_equip_cost)
# 4. Return total
```

**Outputs:** Cost calculation script

---

### Task 4.2: Maintenance Cost Calculator
**File:** `module_scripts.py`
**Script:** `wc_calculate_maintenance`

```python
# Input: troop_id, count
# 1. Get total_equip_cost from slot 330
# 2. maintenance_per_unit = equip_cost / 100
# 3. total = maintenance_per_unit * count
# 4. Store per-unit in slot 331
# 5. Return total
```

**Outputs:** Maintenance calculation integrated with party wages

---

### Task 4.3: Upgrade Cost Calculator
**File:** `module_scripts.py`
**Script:** `wc_calculate_upgrade_cost`

```python
# Input: source_troop, target_troop
# 1. Get equip_cost for both
# 2. Get levels for both
# 3. cost = (target_cost - source_cost) + ((target_level - source_level) * 10)
# 4. Store in target's slot 332
# 5. Return cost
```

**Outputs:** Upgrade cost script

---

### Task 4.4: Modification Handler
**File:** `module_scripts.py`
**Script:** `wc_handle_unit_modification`

```python
# Input: troop_id, old_cost, new_cost, unit_count
# 1. delta = new_cost - old_cost
# 2. total_charge = delta * unit_count
# 3. If positive: charge player, display "Upgrade cost: X denars"
# 4. If negative: refund player, display "Refund: X denars"
# 5. Update all affected troops
```

**Outputs:** Modification cost/refund handler

---

### Task 4.5: Weekly Maintenance Trigger
**File:** `module_simple_triggers.py`

```python
# Every 168 hours (weekly):
# 1. For each party in player faction
# 2. For each custom troop in party
# 3. Add maintenance to party wage bill
# OR integrate with existing wage script
```

**Outputs:** Weekly maintenance deduction

---

### Task 4.6: Vassal Cost Sharing System
**File:** `module_scripts.py`

```python
# wc_toggle_vassal_cost_sharing
# - Store setting in global variable
# - Display current status

# wc_calculate_vassal_army_costs
# - Iterate vassal parties
# - Sum custom troop maintenance
# - If player covering: deduct from player, add sentiment
# - If not: apply sentiment penalty
```

**Outputs:** Vassal cost management scripts

---

### Task 4.7: Cost Display Integration
**File:** `module_presentations.py`, `module_game_menus.py`

```python
# In unit creator: show equipment cost total
# In party screen: show custom troop maintenance
# In finance report: show "Custom Unit Maintenance: X/week"
```

**Outputs:** Cost visibility in UI

---

## Epic 4 Deliverables Summary

| Task | Script | Purpose |
|------|--------|---------|
| 4.1 | `wc_calculate_equipment_cost` | Sum item costs |
| 4.2 | `wc_calculate_maintenance` | Weekly upkeep |
| 4.3 | `wc_calculate_upgrade_cost` | Upgrade pricing |
| 4.4 | `wc_handle_unit_modification` | Change cost/refund |
| 4.5 | Weekly trigger | Maintenance collection |
| 4.6 | Vassal scripts | Cost sharing |
| 4.7 | UI integration | Display costs |

---

# Epic 5: Main Menu Culture Tool

## Objective
Configure cultures outside campaigns for reuse and custom battles.

## Design Decisions

### Storage Format

External file: `Data/wc_cultures.txt`

```
# Warband Cultures Save Format
CULTURE_BEGIN
  name: My Custom Culture
  title_king: Emperor
  title_lord: Duke
  TROOP_BEGIN
    tier: 1
    name: Imperial Recruit
    mounted: 0
    str: 7
    agi: 5
    skills: ironflesh=1,athletics=1
    equipment: itm_leather_jerkin,itm_sword_medieval_a
  TROOP_END
  TROOP_BEGIN
    tier: 2
    ...
  TROOP_END
CULTURE_END
```

### Main Menu Entry

Add to main menu after "Custom Battle":
```
"Configure Cultures" → wc_culture_tool presentation
```

## Detailed Tasks

### Task 5.1: Main Menu Integration
**File:** `module_game_menus.py`

```python
# Add menu option to main menu
("wc_culture_tool", [], "Configure Cultures", [
    (start_presentation, "prsnt_wc_culture_tool"),
]),
```

**Outputs:** Main menu entry point

---

### Task 5.2: Culture Tool Presentation
**File:** `module_presentations.py`
**Presentation:** `wc_culture_tool`

**UI Layout:**
```
+--------------------------------------------------+
| WARBAND CULTURES - Culture Manager               |
+--------------------------------------------------+
| Saved Cultures:          | Culture Details:      |
|   [x] Swadian Empire     |   Troops: 10          |
|   [ ] Northern Raiders   |   Forks: 3            |
|   [ ] Desert Kingdom     |   Avg Tier: 3.2       |
|                          |                       |
| [New] [Load] [Delete]    | [Edit] [Duplicate]    |
+--------------------------------------------------+
| [Import from Campaign]   [Back to Menu]          |
+--------------------------------------------------+
```

**Outputs:** Culture management UI

---

### Task 5.3: File Save Script
**File:** `module_scripts.py`
**Script:** `wc_save_culture_to_file`

```python
# Input: culture_index
# 1. Open file handle
# 2. Write culture header (name, titles)
# 3. For each troop in culture:
#    - Write all slot data in text format
# 4. Close file
```

**Note:** M&B has limited file I/O; may need alternative approach using string storage

**Outputs:** Culture export script

---

### Task 5.4: File Load Script
**File:** `module_scripts.py`
**Script:** `wc_load_culture_from_file`

```python
# 1. Parse file
# 2. Allocate template troops
# 3. Populate slots from file data
# 4. Apply configurations
```

**Outputs:** Culture import script

---

### Task 5.5: Campaign Import
**File:** `module_scripts.py`
**Script:** `wc_import_culture_from_campaign`

```python
# Input: culture_faction_id from save
# 1. Scan all custom troops belonging to culture
# 2. Export slot data to file format
# 3. Write to wc_cultures.txt
# 4. Offer "fork" option (new name, independent copy)
```

**Outputs:** Campaign-to-file export

---

### Task 5.6: Custom Battle Integration
**File:** `module_game_menus.py`, `module_scripts.py`

```python
# In custom battle setup:
# 1. Add "Custom Cultures" section
# 2. List saved cultures
# 3. On selection, load culture troops
# 4. Make available for battle party composition
```

**Outputs:** Custom battle culture selection

---

### Task 5.7: Title Configuration
**File:** `module_presentations.py`

```python
# Part of culture creation flow:
# Title Selection:
#   King equivalent: [King/Khan/Sultan/Emperor/Chief/Custom...]
#   Lord equivalent: [Lord/Jarl/Bey/Duke/Thane/Custom...]
#
# Store selections in culture file
```

**Outputs:** Title customization UI

---

## Epic 5 Deliverables Summary

| Task | Component | Purpose |
|------|-----------|---------|
| 5.1 | Menu entry | Access point |
| 5.2 | Culture tool UI | Management interface |
| 5.3 | Save script | Export to file |
| 5.4 | Load script | Import from file |
| 5.5 | Campaign import | Export existing culture |
| 5.6 | Custom battle | Use cultures in battles |
| 5.7 | Title config | Customize faction titles |

---

# Implementation Order

## Dependencies

```
Epic 2 (Culture System)
    └── Epic 3 (Unit Tree) - uses culture infrastructure
            └── Epic 4 (Economics) - uses unit data
                    └── Epic 5 (Menu Tool) - exports complete cultures
```

## Recommended Sequence

1. **Epic 2** - Foundation for all culture features
2. **Epic 3.1-3.2** - Template troops and allocation
3. **Epic 3.3-3.5** - Unit creation UI
4. **Epic 3.6-3.9** - Validation and integration
5. **Epic 4** - Economic layer on top
6. **Epic 5** - External tools last

---

# Risk Assessment Updates

| Risk | Status | Notes |
|------|--------|-------|
| UI too limited | **Mitigated** | Prototype confirms capability |
| 100 troops insufficient | **Low** | 10 per culture is comfortable |
| Save compatibility | **On track** | Slot system proven |
| File I/O limitations | **New risk** | M&B file ops limited; may need workaround |

---

# Slot Schema Summary (Updated Planning Gate 2)

## Troop Slots (300-399)

| Range | Purpose |
|-------|---------|
| 300-309 | Unit definition (is_custom, culture, tier, mounted, stats) |
| 310-329 | Skills (ironflesh, power_strike, athletics, etc.) |
| 330-339 | Economics (equip_cost, maintenance, upgrade_cost) |
| 340-349 | Upgrade tree (upgrades_to_1/2, from, fork_count, tree_total, root, depth) |
| 350-365 | Armor (head, body, foot, hand × 4 options each) |
| 370-381 | Weapon loadouts (3 loadouts × 4 slots) |
| 385-387 | Horse slots (mounted units only) |
| 390-395 | Proficiencies (1h, 2h, polearm, archery, xbow, throwing) |
| 396-399 | Display/config (name_str, name_type, is_configured, variant_mask) |

## Settlement Slots (400-412)

| Slot | Purpose |
|------|---------|
| 400-409 | Culture percentages (10 cultures) |
| 410 | Culture shift rate |
| 411 | Last update timestamp |
| 412 | Population density |

## Faction Slots (200-211) - Culture Template Management

| Slot | Purpose |
|------|---------|
| 200 | template_next_idx (next available 0-9) |
| 201 | template_count (total allocated) |
| 202-206 | custom_tier_1-5_troop (tier roots) |
| 207 | tree_fork_total |
| 208 | unit_tree_configured |
| 209-211 | name_string, title_king, title_lord |

## Player Culture Factions Added

| Faction | Culture Index | Template Range |
|---------|---------------|----------------|
| fac_culture_7 | 7 | 60-69 |
| fac_culture_8 | 8 | 70-79 |
| fac_culture_9 | 9 | 80-89 |
| fac_culture_10 | 10 | 90-99 |

---

# Next Steps

**Epic 2 is complete.** Proceed to **Epic 3** implementation starting with:

1. Task 3.1: Define 100 template troops in module_troops.py
2. Task 3.2: Template allocation system script
3. Task 3.3: Unit creation presentation

The design provides concrete specifications for all scripts, presentations, and data structures needed.
