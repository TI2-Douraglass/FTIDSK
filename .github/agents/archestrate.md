---
description: Repository-aware resolution layer for Antigravity Kit. Forces agents to consult local .agent structure and fallback to GitHub repository when needed.
---

# 🔎 Antigravity Repository Resolver

You MUST consult the Antigravity Kit repository structure before making assumptions about agents, skills, workflows, or scripts.

Repository:
https://github.com/vudovn/antigravity-kit

RAW Base (fallback):
https://raw.githubusercontent.com/vudovn/antigravity-kit/main/

---

# 📦 Source of Truth Priority (STRICT ORDER)

## 1️⃣ Local Workspace (PRIMARY)
Always check local files FIRST:

.agent/
├── agents/
├── skills/
│   └── <skill>/
│       ├── SKILL.md
│       ├── references/
│       └── scripts/
├── workflows/
└── scripts/

If the file exists locally → USE IT as the authoritative source.

---

## 2️⃣ Remote Repository (FALLBACK)
If the required file does NOT exist locally, resolve it from the official repository using RAW paths:

| Type | RAW Path |
|------|----------|
| Agent | `.agent/agents/<agent>.md` |
| Skill | `.agent/skills/<skill>/SKILL.md` |
| Workflow | `.agent/workflows/<workflow>.md` |
| Scripts | `.agent/scripts/*` or `.agent/skills/<skill>/scripts/*` |
| References | `.agent/skills/<skill>/references/*` |

Example:
https://raw.githubusercontent.com/vudovn/antigravity-kit/main/.agent/skills/security-auditor/SKILL.md

---

# 🧠 Mandatory Skill Loading Protocol (NON-NEGOTIABLE)

When any skill is required, you MUST execute this sequence:

### STEP 1 — Load Core Definition
Read:
.agent/skills/<skill>/SKILL.md

### STEP 2 — Load Deep Knowledge (if referenced)
If SKILL.md mentions references:
.agent/skills/<skill>/references/*

### STEP 3 — Suggest Execution Scripts (if applicable)
If validation, scanning, or automation is required:
.agent/skills/<skill>/scripts/*

Never skip SKILL.md.

---

# 🎯 Agent Resolution Rules

When an agent is invoked (e.g., backend-specialist, security-auditor):

1. Locate agent definition:
   .agent/agents/<agent>.md
2. If missing locally → fetch from repository RAW
3. Extract:
   - Domain expertise
   - Required skills
   - Execution constraints
4. Only then proceed with task execution

---

# 🧩 Workflow Resolution Rules

Before executing orchestration or complex tasks:

1. Check:
   .agent/workflows/
2. If a matching workflow exists → FOLLOW IT
3. If not found locally → consult repository version
4. NEVER invent workflows when one exists in the kit

---

# 🔐 Orchestration Compliance Hook

When in ORCHESTRATION MODE:
- Validate agent definitions from repository
- Validate required skills per agent
- Ensure minimum 3 agents rule
- Ensure verification scripts are discoverable in:
  .agent/scripts/

---

# 🛠️ Script Discovery Policy

For any validation, lint, or security step:

Search in this order:
1. .agent/scripts/
2. .agent/skills/<skill>/scripts/
3. Remote repository scripts (fallback)

If a script exists, it MUST be preferred over ad-hoc logic.

---

# 🚫 Hard Restrictions

You are FORBIDDEN to:
- Assume agent capabilities without checking repository
- Invent skills that are not defined in .agent/skills/
- Skip SKILL.md when a skill is required
- Bypass repository consultation during orchestration tasks

---

# ✅ Expected Behavior Summary

For EVERY complex task:
1. Inspect local .agent/
2. Resolve missing definitions via GitHub RAW
3. Load SKILL.md (mandatory)
4. Follow workflow if available
5. Execute orchestration with validated agents
6. Prefer official scripts over custom logic

Failure to consult the repository structure = invalid orchestration.
