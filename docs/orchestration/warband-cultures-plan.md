# Warband Cultures Mod - Implementation Plan

> **Claude Reference:** `_bmad/_orchestration/plans/orch-warband-cultures-20260119.yaml`
> **Created:** 2026-01-19
> **Status:** Ready for Execution

---

## Summary

This plan implements a comprehensive Mount & Blade: Warband mod with:

1. **Dynamic Culture System** - Settlement cultures change based on faction control, population, and proximity
2. **Custom Player Culture** - Create your own faction with configurable titles
3. **Dynamic Unit Tree Builder** - Build your troop tree through upgrades, not upfront
4. **Economic System** - Equipment-based upgrade costs, maintenance, vassal cost sharing
5. **Main Menu Tool** - Configure cultures outside campaigns, use in custom battles

---

## Approach

### Why Planning Gates?

This mod has significant technical unknowns. The M&B Module System has capabilities we need to prototype before committing to detailed designs:

- **Presentation system limits** affect UI complexity
- **Slot system behavior** affects data persistence
- **Existing patterns** should inform our approach

We use **4 planning gates** to adapt the plan as we learn.

### Complexity Assessment

| Dimension | Score | Notes |
|-----------|-------|-------|
| Complexity | 5/5 | Multiple interconnected systems, runtime mods in compile-time framework |
| Risk | 3/5 | Save compatibility, UI limitations |
| Ambiguity | 2/5 | Requirements clear, implementation uncertain |
| Cross-functional | 4/5 | Game design, scripting, UI, economics |

---

## Phases Overview

### Epic 1: Foundation & Technical Spike (4h)

**Goal:** Validate our approach works before building on it.

| Task | Purpose |
|------|---------|
| Set up Module System | Working dev environment |
| Analyze recruitment system | Understand existing patterns |
| Prototype presentations | Test UI capabilities |
| Prototype troop slots | Verify save persistence |
| Analyze troop/faction structure | Document formulas |

**Deliverables:**
- Working Module System environment
- Technical capabilities document
- Proof of concept for key systems

**PLANNING GATE:** After this epic, we design the detailed UI and data schemas.

---

### Epic 2: Dynamic Culture System (3h)

**Goal:** Settlements gain/lose culture based on control and proximity.

| Feature | Details |
|---------|---------|
| Culture storage | % values in settlement slots |
| Influence factors | Faction control (primary), proximity, population |
| Scaling | Recruitment probability = culture%² |
| Updates | Daily/weekly triggers |
| Display | Culture shown in settlement info |

**PLANNING GATE:** Refine unit tree design based on patterns learned.

---

### Epic 3: Custom Unit Tree Builder (6h)

**Goal:** Players build their troop tree dynamically through upgrades.

#### Template Troop Pool
- ~100 pre-defined "blank" troops in module_troops.py
- Configured at runtime via slots
- Supports ~10 custom factions

#### Faction Creation Flow
1. Player creates faction → title selection (King/Khan/Sultan...)
2. Customize base recruit (stats, equipment)
3. First unit in tree established

#### Unit Creation (On Upgrade)
1. Upgrade unit without defined path → creation flow triggers
2. Select mounted/dismounted
3. Allocate stat points (constrained by tier)
4. Allocate skill points (constrained by tier)
5. Browse equipment filtered by stats/tier
6. Build loadout (grouped weapons)
7. Select armor options (1-3 per slot)
8. Optionally create second upgrade path (fork)

#### Constraints
- Max 2 branches per unit
- ~4 forks total (or 1 per tier)
- Max tier 5 (no further upgrades)

**PLANNING GATE:** Finalize economic formulas based on data structures.

---

### Epic 4: Economic System (2h)

**Goal:** Realistic costs tied to equipment and unit quality.

| System | Formula |
|--------|---------|
| Upgrade cost | Avg equipment cost (new) - Avg equipment cost (previous) |
| Maintenance | Based on loadout equipment costs |
| Modification | Pay/refund delta × unit count |
| Vassal option | Player can cover vassal upgrade costs |
| Sentiment | Army costs affect vassal relations |

**PLANNING GATE:** Design main menu tool architecture.

---

### Epic 5: Main Menu Culture Tool (3h)

**Goal:** Manage cultures outside campaigns.

| Feature | Details |
|---------|---------|
| Culture browser | View/edit saved cultures |
| Unit tree editor | Same UI as in-game |
| External storage | Save to JSON/YAML file |
| Campaign import | Import from existing campaign |
| Fork option | Avoid conflicts between campaigns |
| Custom battles | Select custom cultures for quick battles |
| Cost warnings | Alert when loading modified culture |

---

### Epic 6: Integration & Polish (2h)

**Goal:** Ship it.

- Full integration testing
- Save compatibility verification
- Performance optimization
- Steam Workshop packaging

---

## What You'll Get

### For Players

1. **Dynamic World** - Cultures shift as factions conquer territory
2. **Your Faction, Your Way** - Custom titles, custom troops
3. **Emergent Gameplay** - Build your army doctrine through play
4. **Meaningful Choices** - Equipment affects costs, forks are limited
5. **Persistence** - Cultures survive across sessions

### For Modders

- Well-documented slot schemas
- Extensible culture system
- Reusable presentation templates

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Presentation too limited | Technical spike first; simplify UI if needed |
| 100 troops insufficient | Can increase to 150-200; monitor usage |
| Save compatibility | Use proven slot system; test incrementally |
| Performance | Batch culture updates; optimize at integration |

---

## Estimated Timeline

| Epic | Duration | Cumulative |
|------|----------|------------|
| 1. Foundation | 4h | 4h |
| 2. Culture System | 3h | 7h |
| 3. Unit Tree | 6h | 13h |
| 4. Economics | 2h | 15h |
| 5. Menu Tool | 3h | 18h |
| 6. Integration | 2h | 20h |

**Total:** ~20 hours of focused work

---

## Next Steps

1. **Approve this plan** to begin execution
2. **Epic 1** starts immediately with Module System setup
3. **First planning gate** adapts remaining design based on discoveries

Ready to proceed?
