# CLAUDE.md

**PROJECT: Warband Cultures**
**DO NOT CONFUSE WITH: binful, AV_custom, nestfolio, batchbook, or other projects**
**WORKING DIRECTORY: /Users/NPope97/Warband_Cultures**

## Project Identity

Warband Cultures is a project for Mount & Blade: Warband culture/faction development.

---

## BMAD Workflow Executor Mode

**SYSTEM UPGRADE NOTICE:** The BMAD system uses a two-phase orchestration model with planning gates, background monitoring, and autonomous plan adjustment. This enables complex multi-step tasks to be properly scoped, executed with the right specialists, and adapted when issues arise.

**Key Documentation:**
- Planning Gate Protocol: `AV_custom/_bmad/core/docs/PLANNING_GATE_PROTOCOL.md`
- Workflow Integration Map: `AV_custom/_bmad/_orchestration/WORKFLOW_INTEGRATION_MAP.md`

### Task Triage (Do This First)

Before loading any skills, classify the request:

| Request Type | Indicators | Action |
|-------------|-----------|--------|
| **Conversational** | Questions, explanations, "what is", "how does" | Answer directly |
| **Single-step task** | One clear action, affects 1-2 files max | Execute directly |
| **Technical task** | Code changes, reviews, debugging (defined scope) | → Skills registry |
| **Multi-step/chained** | "X and then Y", sequential tasks, 3+ steps | → Meta-orchestration |
| **Undefined scope** | "Review the project", broad requests | → Meta-orchestration |

**Decision Flow:**
```
1. Conversational? → Answer directly, STOP
2. Single-step? → Execute directly, STOP
3. Chained tasks? ("X and then Y") → Meta-orchestration
4. Undefined scope? → Meta-orchestration
5. Technical? (defined scope) → Skills registry → matched workflow
6. Complex? (3+ steps, cross-domain) → Meta-orchestration
7. Grey area? → Load request-router for assessment
```

### Two-Phase Orchestration

**Phase 1 - Meta-Orchestration ("Planning the Planning"):**
- Discovery first: What do I need to know before planning?
- Can this be fully planned upfront, or needs planning gates?
- Use planning gates liberally - if later phases benefit from earlier context, add a gate

**Phase 2 - Orchestration ("Detailed Planning"):**
- Runs at initial planning AND at each planning gate
- Break down using epics/stories patterns
- Assign agents, skills, workflows per task
- Decide execution strategy (parallel, adversarial, etc.)
- **FIX deficiencies** in the plan - only flag true AMBIGUITIES to user

### Technique Assessment Protocol

When assessing complexity for meta-orchestration, follow this checklist:

**Step 1: Score all dimensions** (reference: `bmad:core:skills:orchestration:technique-reassessor`)
| Dimension | Scale | Description |
|-----------|-------|-------------|
| complexity | 0-4 | Technical complexity, systems affected |
| risk | 0-4 | Impact if something goes wrong |
| ambiguity | 0-4 | Clarity of requirements |
| cross_functional | 0-3 | Breadth of domains involved |
| stakeholders | 0-2 | External parties affected |

**Step 2: Check ALL trigger conditions for each technique**

Multi-mode techniques require checking EACH mode independently:

| Technique | Mode | Trigger | Intensity |
|-----------|------|---------|-----------|
| advanced_elicitation | **elicitation** | ambiguity >= 3 | moderate |
| advanced_elicitation | **validation** | complexity >= 4 OR risk >= 3 | moderate |
| advanced_elicitation | **validation** | complexity >= 3 AND risk >= 3 | **deep** |
| adversarial_review | - | risk >= 3 OR complexity >= 3 | standard/enhanced |
| party_mode | - | cross_functional >= 2 OR stakeholders >= 1 | standard/enhanced |
| brainstorming | - | ambiguity >= 3 AND user_uncertain | standard/enhanced |

**Step 3: Document ALL triggered techniques with their modes**

If multiple modes trigger for the same technique (e.g., both elicitation AND validation for advanced_elicitation), document BOTH in the technique assessment.

### Background Orchestration

During execution, the background orchestrator monitors and adjusts autonomously:
- Breaking down stuck tasks into smaller steps
- Changing execution strategy if current approach failing
- Re-assigning to different agents as needed
- Reworking the plan structure to address blockers

**Flag to user ONLY when:** The end result of the plan must change (not intermediate steps).

### Clarifying Questions vs. Brainstorming

- **Clarifying questions**: User has clear idea, prompt lacked specificity
- **Brainstorming**: User may NOT have clear idea - trigger brainstorming workflow

### This Is Not a Downgrade

This executor mode gives you access to 74+ specialized workflows, intelligent planning with gates, autonomous execution monitoring, and proper resource allocation. Fast for simple work, thorough for complex work, adaptive when plans need adjustment.

---

## BMAD Integration

This project uses centralized BMAD with MCP skill discovery:
- **Token reduction:** 85% (on-demand skill loading)
- **Skills available:** 96+ across all modules
- **MCP configuration:** See .mcp.json
- **Centralized location:** `/Users/NPope97/AV_custom/_bmad`

### Available BMAD Agents

Use BMAD agents for:
- **Planning:** `/bmad:bmm:agents:pm`
- **Development:** `/bmad:bmm:agents:dev`
- **Architecture:** `/bmad:bmm:agents:architect`
- **Testing:** `/bmad:bmm:agents:tea`

**Skill discovery:** Type `/bmad:` to see all available skills via MCP

---

## Project-Specific Notes

**Add project-specific conventions, patterns, and important information here as you work on the project.**

---

## Need Help?

- BMAD Documentation: `/Users/NPope97/AV_custom/_bmad/core/docs/`
- MCP Configuration: See `.mcp.json` in project root
- Skill Discovery: Type `/bmad:` to explore available agents and workflows

---

**You are working on Warband Cultures.** Always verify with `pwd` if unsure.
