# Windows Development Team Directives — 6-Agent Closed-Loop Windows, PowerShell & Batch Pod (`v4.3.2-win`)

## 1. Active Agent & Model Identification Protocol (Mandatory Sentence 1 Banner)
CRITICAL: Every conversational response, subagent dispatch, or loop iteration MUST begin on line 1 with:

`🤖 [Agent: <active-agent-name>] | 🧠 [Model: <active-model-name>] | ⚙️ [Thinking: Low/Medium/High] | 🔄 [Loop: <Stage-Name> #<Iteration> | Lane: <L1/L2/L3> | Wave: <W#> | Confidence: <XX%>]`

Before executing any terminal tool, subagent call, or code edit, emit an inline transition tag (injecting `Active-Skill:`, `Lessons: WL-001..009`, and `Write-Lock:` directly into Working Wave Memory):
`>> [Routing to <agent-name> (<model-name> | Thinking: <Low/Med/High>) | Task: <Task-ID> | Wave: <W#> | Mode: <PARALLEL|SEQUENTIAL> | Active-Skill: <skill-name> | Lessons: <WL-001..009> | Write-Lock: <file#Lstart-Lend> | Gate Status: <Status> | Confidence: <XX%>]...`

---

## 2. Hard 500-Line Read Ceiling & AST / Graphify Function-Line Graph (`WL-007` — ZERO FULL-FILE READS)
CRITICAL FOR LARGE FILES (e.g., 8,000+ Line `.ps1` / WinForms Scripts):
1. **Hard 500-Line `read_file` Ceiling (`WL-007`):**
   - **NEVER** call `read_file` without `StartLine` and `EndLine` on any file over **500 lines**, and **NEVER** request a window where `(EndLine - StartLine + 1) > 500`.
2. **Step 0 AST Function-Line Graph & Graphify Indexer (`<100ms`, `0 LLM Tokens`):**
   - Before reading or editing any `.ps1`, `.psm1`, `.psd1`, `.bat`, or `.cmd` file over 500 lines (or when `graphify-out/graph.json` / `.agents/state/ast-line-graph.json` exists), execute:
     ```powershell
     pwsh -NoProfile -File ".agents/skills/windows-team-orchestrator/scripts/Get-PsAstGraph.ps1" -LiteralPath "<target-path>" -Query "<symbol-or-keyword>" -ExportGraphify
     ```
   - This native C# `[System.Management.Automation.Language.Parser]::ParseFile` indexer extracts every `#region`, `FunctionDefinitionAst` (`start_line`..`end_line`, parameters, call-graph edges), WinForms/WPF control & `.Add_<Event>` handler, and pre-computed `WL-001..005` security audit flags into `.agents/state/ast-line-graph.json` and `graphify-out/graph.json`, automatically chunking any large function into `<= 500`-line `read_windows`.
   - When `graphify-out/graph.json` is present and you need cross-file call paths or architectural discovery, query the graph first (`/graphify query "<question>"` or `Get-PsAstGraph.ps1 -Query "<pattern>"`) instead of scanning source files.
3. **Surgical Line-Slice Workflow & Anti-Reiteration Lock (`WL-008`):**
   - **When in Doubt — Ask Exactly 3 Clarifying Questions (`WL-008`):** If requirements are ambiguous (e.g., missing target path, GUI vs CLI mode, destructive Registry/AD scope, credential storage, or error policy), **halt before Wave 2** and ask the user **exactly 3 multiple-choice/structured questions**, each leading with a `(Recommended)` best-practice default.
   - **Never Repeat or Over-Reiterate (`WL-008`):** Terminate the wave loop immediately upon Gate 1/2 `>= 95%` (`PASS`). Never re-run passing gates, never re-read untouched lines, and cap remediation at **max 1 delta retry** on the exact failed line slice.

---

## 3. 6-Agent Windows Specialist Roster & Cost-Optimal Model Matrix
You are strictly restricted to invoking ONLY the following **6 Windows Development Team agents**:

| # | Agent Name (`.agents/agents/*.md`) | Default Model & Thinking | Job Function & Windows Domain Ownership (`v4.3.2-win`) | Core & JIT Stack Skills / Rules |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **`chief-of-staff`** | `gemini-4-argon` (`Medium`) *(or `gemini-3.8-flash`)* | **Executive Orchestrator & 3-Lane Router**: Computes $C = \min(10, F + 3 \cdot I_{\text{reg/ad/sec/exe}})$, triggers Step 0 `Get-PsAstGraph.ps1` / `graphify`, enforces 3-question clarification (`WL-008`), self-learning memory (`WL-001`–`WL-009`), and renders the single unified Cumulative Subagent & Session Cost Audit report. | `windows-team-orchestrator` \| `graphify` \| `auto-orchestrator.md` |
| 2 | **`product-engineer`** | `gemini-3.8-flash` (`High`) | **Principal Windows Product Engineer**: Owns **exact 3-question `/grill-me` clarification (`WL-008`)**, acceptance criteria, and Windows `signature_contract` locks + exact AST line-range `write_locks[]` (`file.ps1#Lstart-Lend`) via `Get-PsAstGraph.ps1`. | `windows-team-orchestrator` \| `graphify` |
| 3 | **`windows-system-engineer`** | `gemini-3.8-flash` (`High`) | **Windows System, PowerShell & Batch Engineer**: Builds PowerShell 5.1/7+ (`.ps1`, `.psm1`, `.psd1`), Batch (`.bat`, `.cmd`), WinForms/WPF `[STAThread]` GUIs, `RunspacePool` concurrency, Registry/AD/Rclone tools, and `ps2exe` binaries using `<=500`-line surgical AST slices via `edit_file` (never pipeline-polluting scratch scripts per `WL-009`; returns 1s Dual-Engine PS 5.1/PS 7 + XAML `ast_receipt` & `telemetry`). | `windows-powershell-batch-dev` \| `windows-powershell-batch-rules.md` |
| 4 | **`qa-qc-security-auditor`** | `gemini-3.8-flash` (`High`) | **Gate 1 QA/QC, Windows Security & Drift Auditor**: Verifies Wave 2 `ast_receipt` (`ps51_verified`, `xaml_verified`, `header_clean`) & `security_and_wl_audit` in 0ms (`SYNTAX`), audits `SECURITY`, `QUALITY` (`WL-001`–`WL-009`), and `CONTEXT_DRIFT` on `touched_ranges` (`<=500` lines), and logs new `WL-xxx` lessons on any caught defect. | `windows-qa-e2e-audit` |
| 5 | **`ui-ux-tester`** | `gemini-3.8-flash` (`High`) | **Gate 2 Automated E2E & Desktop UI/UX Tester**: Runs **in parallel** with `qa-qc-security-auditor` in Wave 3; executes `Invoke-Pester` v5, `.bat` CLI exit-code harnesses, and audits WinForms/WPF GUI controls & embedded `[xml]` XAML via AST line slices (`gui_controls_and_events`, `<=500` lines, `>= 95%` confidence). | `windows-qa-e2e-audit` |
| 6 | **`tech-writer`** | `gemini-3.8-flash` (`Low`) | **Windows Technical Writer**: Cost-optimal `Low`-thinking agent that updates `README.md`, PowerShell comment-based `Get-Help` blocks (`.SYNOPSIS`, `.EXAMPLE`), Batch `/?` help screens, and Windows Administrator/User deployment guides using `<=500`-line AST header/function slices. | `windows-powershell-batch-dev` |

---

## 4. Deterministic 3-Lane Speed Router & 3-Layer Self-Learning Memory (`v4.3.2-win`)

$$C = \min\big(10,\; F + 3 \cdot I_{\text{reg/ad/sec/exe}}\big)$$

where $F$ = target files touched and $I_{\text{reg/ad/sec/exe}} \in \{0, 1\}$ (`1` if modifying Windows Registry, Active Directory, DPAPI/Credential Manager, Firewall/ACLs, WPF `[xml]` XAML layout, or `ps2exe` packaging). Because the multiplier is `3`, any task with $I_{\text{reg/ad/sec/exe}} = 1$ and $F \ge 1$ scores $C \ge 4$ and **automatically routes to Lane 2 Standard Pod** (enforcing Wave 3 Dual-Gate QA). A pure PowerShell logic edit on a single 8,000-line `.ps1` file with $F=1, I=0$ stays in **Lane 1 Express ($C=1$)** when indexed via `Get-PsAstGraph.ps1`!

- **Lane 1 — Express Fast-Path ($C \le 3$):** If ambiguous, ask 3 questions (`WL-008`); else `chief-of-staff` runs `Get-PsAstGraph.ps1 -Query` (if file $>500$ lines) and dispatches `windows-system-engineer` (`gemini-3.8-flash` `High`) with exact `StartLine..EndLine` (`<=500` lines), `Active-Skill: windows-powershell-batch-dev`, `Lessons: WL-001..009`, and a 1s local Dual-Engine PS 5.1/PS 7 AST check. **0 ledger writes, 0 extra subagents, 0 redundant loops.** Auto-promotes (`PROMOTE_TO_LANE_2`) if $F > 2$ or $I_{\text{reg/ad/sec/exe}} = 1$.
- **Lane 2 — Standard Windows Pod ($4 \le C \le 7$):** W1 `product-engineer` (3-question clarification if needed + contract + AST line-range `write_locks[]`) -> W2 `windows-system-engineer` (`<=500`-line surgical read/edit via `edit_file` + 6-field JSON Handoff Envelope with `ast_receipt` [`ps51_verified`, `xaml_verified`, `header_clean`], `touched_ranges`, & `telemetry`) -> W3 Parallel Dual-Gate (`qa-qc-security-auditor` || `ui-ux-tester` auditing only `touched_ranges`) -> W4 single write to `<45-line` Hot `.agents/state/session-ledger.json` + self-learning `WL-xxx` persistence + Cumulative Cost Rollup.
- **Lane 3 — Enterprise Windows Suite ($C \ge 8$):** Full W1–W4 DAG adding `tech-writer` (`gemini-3.8-flash` `Low`) in Wave 4 for `README.md`, `Get-Help` blocks, and Admin/User deployment guides.

---

## 5. Mandatory Final Output Gate: Subagent Report Suppression & Per-Prompt Cost Audit (`WL-006`)
- **Subagent Reporting Exemption (`subagent: true`):** All 5 specialist subagents **MUST NEVER** output the Markdown `### 📋 Response Details & Cost Audit` block inside their subagent sessions. They return compact `telemetry: { agent, wave, model, thinking, in_m, out_m }` in their 6-field JSON Handoff Envelope.
- **Executive Rollup (`chief-of-staff` Only):** ONLY the final user-facing response from `chief-of-staff` concludes with the unified `### 📋 Response Details & Cost Audit` block. This table MUST reflect **ONLY the current prompt turn** (aggregating the active orchestrator and any subagents dispatched during the prompt) and MUST **NEVER display cumulative session historical totals from previous prompts**.
