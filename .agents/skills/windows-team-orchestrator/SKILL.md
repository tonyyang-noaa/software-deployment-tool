---
name: windows-team-orchestrator
description: 6-Agent Windows Development Team Orchestrator skill (v4.3.2-win) governing the Deterministic 3-Lane Router, Hard 500-Line Read Ceiling (WL-007), 3-Question Ambiguity Gate & Zero-Reiteration Lock (WL-008), Dual-Engine PS 5.1/PS 7 + XAML AST Function-Line Graph & SHA256 Receipt (Get-PsAstGraph.ps1, WL-009..WL-012), and 6-Field Telemetry Rollup.
---

# Windows Team Orchestrator Skill (`windows-team-orchestrator` | `v4.3.2-win`)

## 1. Step 0 Pre-Flight: 3-Question Ambiguity Gate (`WL-008`) & 500-Line AST/Graphify Slicing (`WL-007`, `WL-011`)
1. **When in Doubt — Ask Exactly 3 Clarifying Questions (`WL-008`):**
   - Before dispatching Wave 2 implementation, evaluate whether the request has material ambiguity. If ambiguous, **HALT immediately** and ask the user **exactly 3 structured questions** (via `ask_question` or `/grill-me`), with the best-practice option placed first and prefixed with `(Recommended)`.
2. **Strict 500-Line Read Ceiling (`WL-007`) & Compact Receipt (`WL-011`):**
   - **NEVER** call `read_file` without `StartLine` and `EndLine` on any file exceeding **500 lines** (including `.agents/state/ast-line-graph.json`), and **NEVER** request `(EndLine - StartLine + 1) > 500`.
   - Run `pwsh -NoProfile -File ".agents/skills/windows-team-orchestrator/scripts/Get-PsAstGraph.ps1" -LiteralPath "<target>" -Query "<keyword>" -ExportGraphify` to index scripts in `<100ms` (0 LLM tokens) and write `.agents/state/ast-receipt-latest.json` (`<30` lines: `sha256`, `git diff` `touched_ranges`, `ast_receipt`, `xaml_control_check`, and `security_and_wl_audit`).

---

## 2. Deterministic Complexity Score, Cost-Optimal Model Selection & Per-Lane Telemetry (`WL-012`)
At the start of every request, `chief-of-staff` computes:

$$C = \min\big(10,\; F + 3 \cdot I_{\text{reg/ad/sec/exe}}\big)$$

where:
- $F$ = number of target files touched (`.ps1`, `.psm1`, `.psd1`, `.bat`, `.cmd`, `.reg`, `.json`)
- $I_{\text{reg/ad/sec/exe}} \in \{0, 1\}$ = `1` ONLY if the task mutates Windows Registry, Active Directory, Credential Manager/DPAPI, Firewall/ACLs, or packaging pipeline security; routine PowerShell logic, WPF `[xml]` XAML layout edits, and `build_exe.ps1` recompiles score $I = 0$ (staying in **Lane 1 Express** when $F \le 3$, guarded by 0-token `Get-PsAstGraph.ps1` + `build_exe.ps1` pre-flight checks).

| Speed Lane | Score Range | Execution Topology |
| :--- | :--- | :--- |
| **Lane 1: Express Fast-Path** | $C \le 3$ | `chief-of-staff` (3 questions if ambiguous; runs `Get-PsAstGraph.ps1 -Query` if file $>500$ lines) $\rightarrow$ `windows-system-engineer` (`gemini-3.8-flash` `High`: reads/edits `StartLine..EndLine <= 500` lines with `Lessons: WL-001..012` + 1s Dual-Engine `Get-PsAstGraph.ps1` receipt) $\rightarrow$ append 1 JSONL record to `.agents/state/task-history.jsonl` & update per-lane counters in `.agents/state/session-ledger.json`. Auto-promotes (`PROMOTE_TO_LANE_2`) if $F > 2$ or $I_{\text{reg/ad/sec/exe}} = 1$. |
| **Lane 2: Standard Windows Pod** | $4 \le C \le 7$ | **W1:** `product-engineer` (contract + AST line-range `write_locks[]`) $\rightarrow$ **W2:** `windows-system-engineer` (`<=500`-line slice edit via `edit_file` & 6-field JSON Handoff Envelope with `sha256`, `ps51_verified`, `xaml_verified`, `header_clean`) $\rightarrow$ **W3 (Parallel):** `qa-qc-security-auditor` $\parallel$ `ui-ux-tester` (auditing `.agents/state/ast-receipt-latest.json` + `touched_ranges <= 500` lines) $\rightarrow$ **W4:** update `<45-line` `session-ledger.json` + append `task-history.jsonl` + self-learning `WL-xxx` check (capped at `max_lessons: 12`) + Cumulative Cost Audit. |
| **Lane 3: Enterprise Windows Suite** | $C \ge 8$ | Full W1–W4 DAG adding `tech-writer` (`gemini-3.8-flash` `Low`) in Wave 4 for `README.md`, PowerShell `Get-Help` blocks, and Admin/User deployment guides. |

---

## 3. 3-Layer Self-Learning Closed-Loop Memory Architecture
1. **Layer 1 — Working Wave Memory (`<135-Token` 6-Field JSON Handoff Envelope):**
   Every subagent returns ONLY this compact JSON envelope at the end of its turn (**never rendering a Markdown Cost Audit table inside its sub-session per `WL-006`**):
   ```json
   {
     "status": "COMPLETED",
     "files_touched": ["ps_deploy.ps1#L2775-L2798"],
     "exported_symbols_and_tokens": ["Update-ConfigPaths", "-LiteralPath", "ExitCode:0"],
     "ast_receipt": { "cmd": "Get-PsAstGraph.ps1", "sha256": "A1B2C3...", "exit_code": 0, "verified": true, "ps51_verified": true, "xaml_verified": true, "header_clean": true, "touched_ranges": ["L2775-L2798"] },
     "confidence": 99,
     "telemetry": { "agent": "windows-system-engineer", "wave": "W2", "model": "gemini-3.8-flash", "thinking": "High", "in_m": 0.0021, "out_m": 0.0008 }
   }
   ```
2. **Layer 2 — Episodic Hot Run Ledger (`.agents/state/session-ledger.json`), Longitudinal Task Log (`.agents/state/task-history.jsonl`), & Compact Receipt (`.agents/state/ast-receipt-latest.json`):**
   - `session-ledger.json` is strictly `< 45` lines and tracks per-lane `tasks_accepted`, `gate_strikes`, and `retry_tokens_m`.
   - `task-history.jsonl` records 1 compact JSONL line per completed task across all lanes (`L1`, `L2`, `L3`), capped at 500 lines (`WL-012`).
   - `ast-receipt-latest.json` (`< 30` lines) provides `sha256`-bound syntax, XAML control binding, and `WL-001..005` security receipts in ~120 tokens (`WL-011`).
3. **Layer 3 — Semantic Cold Self-Learning Knowledge Base (`.agents/state/orchestrator-config.json`):**
   - Stores permanent Windows anti-regression rules (`WL-001` through `WL-012`, capped at `max_lessons: 12` with automatic consolidation into `Get-PsAstGraph.ps1` checks).
