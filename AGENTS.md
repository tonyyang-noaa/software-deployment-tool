# Windows Development Team Directives — 6-Agent Closed-Loop Windows, PowerShell & Batch Pod (`v4.3.2-win`)

## 1. Active Agent & Model Identification Protocol (Mandatory Sentence 1 Banner)
CRITICAL: Every conversational response, subagent dispatch, or loop iteration MUST begin on line 1 with:

`🤖 [Agent: <active-agent-name>] | 🧠 [Model: <active-model-name>] | ⚙️ [Thinking: Low/Medium/High] | 🔄 [Loop: <Stage-Name> #<Iteration> | Lane: <L1/L2/L3> | Wave: <W#> | Confidence: <XX%>]`

Before executing any terminal tool, subagent call, or code edit, emit an inline transition tag (injecting `Active-Skill:`, `Lessons: WL-001..012`, and `Write-Lock:` directly into Working Wave Memory):
`>> [Routing to <agent-name> (<model-name> | Thinking: <Low/Med/High>) | Task: <Task-ID> | Wave: <W#> | Mode: <PARALLEL|SEQUENTIAL> | Active-Skill: <skill-name> | Lessons: <WL-001..012> | Write-Lock: <file#Lstart-Lend> | Gate Status: <Status> | Confidence: <XX%>]...`

---

## 2. Hard 500-Line Read Ceiling & AST / Graphify Function-Line Graph (`WL-007` — ZERO FULL-FILE READS)
CRITICAL FOR LARGE FILES (e.g., 8,000+ Line `.ps1` / WinForms / WPF Scripts):
1. **Hard 500-Line `read_file` Ceiling (`WL-007`):**
   - **NEVER** call `read_file` without `StartLine` and `EndLine` on any file over **500 lines** (including `.agents/state/ast-line-graph.json`), and **NEVER** request a window where `(EndLine - StartLine + 1) > 500`.
2. **Step 0 AST Function-Line Graph & Compact Receipt (`<100ms`, `0 LLM Tokens`):**
   - Before reading or editing any `.ps1`, `.psm1`, `.psd1`, `.bat`, or `.cmd` file over 500 lines, execute:
     ```powershell
     pwsh -NoProfile -File ".agents/skills/windows-team-orchestrator/scripts/Get-PsAstGraph.ps1" -LiteralPath "<target-path>" -Query "<symbol-or-keyword>" -ExportGraphify
     ```
   - This native C# `[System.Management.Automation.Language.Parser]::ParseFile` indexer extracts every `#region`, `FunctionDefinitionAst`, GUI control/event, XAML control binding, and `WL-001..005` security audit flag into `.agents/state/ast-line-graph.json`, `graphify-out/graph.json`, and a `<30-line` `.agents/state/ast-receipt-latest.json` (`sha256` + `git diff` `touched_ranges`).
3. **Surgical Line-Slice Workflow & Anti-Reiteration Lock (`WL-008`):**
   - **When in Doubt — Ask Exactly 3 Clarifying Questions (`WL-008`):** If requirements are ambiguous, **halt before Wave 2** and ask the user **exactly 3 structured questions**, each leading with a `(Recommended)` best-practice default.
   - **Never Repeat or Over-Reiterate (`WL-008`):** Terminate the wave loop immediately upon Gate 1/2 `>= 95%` (`PASS`). Never re-run passing gates, never re-read untouched lines, and cap remediation at **max 1 delta retry** on the exact failed line slice.

---

## 3. 6-Agent Windows Specialist Roster & Cost-Optimal Model Matrix
You are strictly restricted to invoking ONLY the following **6 Windows Development Team agents**:

| # | Agent Name (`.agents/agents/*.md`) | Default Model & Thinking | Job Function & Windows Domain Ownership (`v4.3.2-win`) | Core & JIT Stack Skills / Rules |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **`chief-of-staff`** | `gemini-4-argon` (`Medium`) *(or `gemini-3.8-flash`)* | **Executive Orchestrator & 3-Lane Router**: Computes $C = \min(10, F + 3 \cdot I_{\text{reg/ad/sec/exe}})$, triggers Step 0 `Get-PsAstGraph.ps1`, enforces 3-question clarification (`WL-008`), self-learning memory (`WL-001`–`WL-012`), and renders the unified Cumulative Subagent & Session Cost Audit report. | `windows-team-orchestrator` \| `graphify` |
| 2 | **`product-engineer`** | `gemini-3.8-flash` (`High`) | **Principal Windows Product Engineer**: Owns **exact 3-question `/grill-me` clarification (`WL-008`)**, acceptance criteria, and Windows `signature_contract` locks + exact AST line-range `write_locks[]` (`file.ps1#Lstart-Lend`) via `Get-PsAstGraph.ps1`. | `windows-team-orchestrator` \| `graphify` |
| 3 | **`windows-system-engineer`** | `gemini-3.8-flash` (`High`) | **Windows System, PowerShell & Batch Engineer**: Builds PowerShell 5.1/7+ (`.ps1`, `.psm1`, `.psd1`), Batch (`.bat`, `.cmd`), WinForms/WPF `[STAThread]` GUIs, `RunspacePool` concurrency, Registry/AD/Rclone tools, and `ps2exe` binaries using `<=500`-line surgical AST slices via `edit_file` (`WL-009`; returns 1s Dual-Engine PS 5.1/PS 7 + XAML `ast_receipt` with `sha256` & `telemetry`). | `windows-powershell-batch-dev` \| `windows-powershell-batch-rules.md` |
| 4 | **`qa-qc-security-auditor`** | `gemini-3.8-flash` (`High`) | **Gate 1 QA/QC, Windows Security & Drift Auditor**: Verifies `.agents/state/ast-receipt-latest.json` (`sha256`, `ps51_verified`, `xaml_verified`, `header_clean`, `security_and_wl_audit`) in 0ms (`SYNTAX`), audits `SECURITY`, `QUALITY` (`WL-001`–`WL-012`), and `CONTEXT_DRIFT` on `touched_ranges` (`<=500` lines). | `windows-qa-e2e-audit` |
| 5 | **`ui-ux-tester`** | `gemini-3.8-flash` (`High`) | **Gate 2 Automated E2E & Desktop UI/UX Tester**: Runs **in parallel** with `qa-qc-security-auditor` in Wave 3; executes `Invoke-Pester` v5 (`tests/*.Tests.ps1`), `.bat` CLI exit-code harnesses, and audits WinForms/WPF GUI controls & XAML bindings via AST slices (`<=500` lines, `>= 95%` confidence). | `windows-qa-e2e-audit` |
| 6 | **`tech-writer`** | `gemini-3.8-flash` (`Low`) | **Windows Technical Writer**: Cost-optimal `Low`-thinking agent that updates `README.md`, PowerShell comment-based `Get-Help` blocks (`.SYNOPSIS`, `.EXAMPLE`), Batch `/?` help screens, and Windows Administrator/User deployment guides using `<=500`-line AST slices. | `windows-powershell-batch-dev` |

---

## 4. Deterministic 3-Lane Speed Router & 3-Layer Self-Learning Memory (`v4.3.2-win`)

$$C = \min\big(10,\; F + 3 \cdot I_{\text{reg/ad/sec/exe}}\big)$$

where $F$ = target files touched and $I_{\text{reg/ad/sec/exe}} \in \{0, 1\}$ (`1` ONLY if mutating Windows Registry, Active Directory, DPAPI/Credential Manager, Firewall/ACLs, or packaging pipeline security; routine PowerShell logic, WPF `[xml]` XAML layout edits, and `build_exe.ps1` recompiles score $I = 0$ and remain in **Lane 1 Express ($C \le 3$)** guarded by 0-token `Get-PsAstGraph.ps1` + `build_exe.ps1` pre-flight checks).

- **Lane 1 — Express Fast-Path ($C \le 3$):** If ambiguous, ask 3 questions (`WL-008`); else `chief-of-staff` runs `Get-PsAstGraph.ps1 -Query` and dispatches `windows-system-engineer` (`gemini-3.8-flash` `High`) with exact `StartLine..EndLine` (`<=500` lines), `Active-Skill: windows-powershell-batch-dev`, `Lessons: WL-001..012`, and a 1s Dual-Engine PS 5.1/PS 7 + XAML AST receipt check, then logs 1 compact telemetry entry to `.agents/state/task-history.jsonl` and updates per-lane counters in `.agents/state/session-ledger.json`. Auto-promotes (`PROMOTE_TO_LANE_2`) if $F > 2$ or $I_{\text{reg/ad/sec/exe}} = 1$.
- **Lane 2 — Standard Windows Pod ($4 \le C \le 7$):** W1 `product-engineer` (contract + AST line-range `write_locks[]`) -> W2 `windows-system-engineer` (`<=500`-line edit via `edit_file` + 6-field JSON Handoff Envelope with `ast_receipt` [`sha256`, `ps51_verified`, `xaml_verified`, `header_clean`], `touched_ranges`, & `telemetry`) -> W3 Parallel Dual-Gate (`qa-qc-security-auditor` || `ui-ux-tester` auditing `.agents/state/ast-receipt-latest.json` + `touched_ranges`) -> W4 update `<45-line` `.agents/state/session-ledger.json` + append `.agents/state/task-history.jsonl` + Cumulative Cost Rollup.
- **Lane 3 — Enterprise Windows Suite ($C \ge 8$):** Full W1–W4 DAG adding `tech-writer` (`gemini-3.8-flash` `Low`) in Wave 4 for `README.md`, `Get-Help` blocks, and Admin/User deployment guides.

---

## 5. Mandatory Final Output Gate: Subagent Report Suppression & Cumulative Cost Audit (`WL-006`)
- **Subagent Reporting Exemption (`subagent: true`):** All 5 specialist subagents **MUST NEVER** output the Markdown `### 📋 Response Details & Cost Audit` block inside their subagent sessions. They return compact `telemetry: { agent, wave, model, thinking, in_m, out_m }` in their 6-field JSON Handoff Envelope.
- **Executive Rollup (`chief-of-staff` Only):** ONLY the final user-facing response from `chief-of-staff` concludes with the unified `### 📋 Response Details & Cost Audit` block aggregating all subagents from the current turn plus the cumulative session total from `.agents/state/session-ledger.json`.
