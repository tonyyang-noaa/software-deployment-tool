---
name: windows-qa-e2e-audit
description: Dual-Gate Verification Skill (v4.3.2-win) for /windows-dev-team covering Gate 1 (0ms SHA256-Bound Dual-Engine PS 5.1/PS 7 + XAML AST & Security-Flag Receipt Reuse via .agents/state/ast-receipt-latest.json, <=500-Line Diff/Slice Auditing, WL-001..012 Quality, Context Drift) and Gate 2 (Deterministic XAML Control/Event Check, Pester v5 Smoke Suite tests/*.Tests.ps1, WinForms/WPF UX & DPI/TabIndex Ergonomics).
---

# Windows Dual-Gate QA, Security & E2E Validation Skill (`windows-qa-e2e-audit` | `v4.3.2-win`)

## 0. Mandatory 500-Line Sliced Audit Rule & Compact Receipt Verification (`WL-007`, `WL-011`)
- **NEVER** read an entire `.ps1`, `.psm1`, or `.bat` file over **500 lines** or `.agents/state/ast-line-graph.json` during Gate 1 or Gate 2 verification.
- Read `.agents/state/ast-receipt-latest.json` (`< 30` lines: `sha256`, `ast_receipt`, `touched_ranges`, `xaml_control_check`, `security_and_wl_audit`) and inspect **only** the modified line ranges (`touched_ranges`, with `(EndLine - StartLine + 1) <= 500`).

---

## 1. Gate 1 Rubric (`qa-qc-security-auditor` — 4 Pillars, `>= 95%` Required)

### Pillar 1: `SYNTAX` (25 pts — 0ms SHA256-Bound Dual-Engine `ast_receipt` Reuse)
- Inspect `.agents/state/ast-receipt-latest.json` and confirm `ast_receipt.verified == true && ps51_verified == true && header_clean == true && xaml_verified == true && exit_code == 0` and non-empty `sha256`. Do **NOT** re-run `Parser::ParseFile` unless files were modified after Wave 2.
- For `.bat`/`.cmd` files, verify balanced parentheses in `if (...) else (...)` blocks and valid `:label` targets within `touched_ranges`.

### Pillar 2: `SECURITY` (25 pts — 0-Token AST Flag Check + Sliced Diff Audit)
- Inspect `security_and_wl_audit` in `.agents/state/ast-receipt-latest.json` (`invoke_expression_lines == []`) and audit `touched_ranges` (`<= 500` lines):
  - Zero hardcoded passwords, tokens, or connection strings (`WL-005` — enforce DPAPI `ConvertTo-SecureString` / `SecretManagement`).
  - Zero unescaped `Invoke-Expression` (`iex`) or unquoted `.bat` path expansions.
  - `[CmdletBinding(SupportsShouldProcess = $true)]` present on destructive system/Registry/AD functions.

### Pillar 3: `QUALITY` (25 pts — `WL-001`..`WL-012` Anti-Regression Audit)
- `WL-001`: `security_and_wl_audit.gci_missing_literalpath_lines` is empty (`0` unguarded `Get-ChildItem -Path` calls) + `ReparsePoint` exclusion on recursive directory traversal.
- `WL-002`: `[System.STAThread]` guard + `RunspacePool` / non-blocking UI for WinForms/WPF.
- `WL-003`: `@echo off`, `setlocal EnableDelayedExpansion`, and `exit /b %ERRORLEVEL%` in Batch scripts.
- `WL-004`: `[System.AppDomain]::CurrentDomain.BaseDirectory` path resolution + `ps_deploy.ico` packaging + `$LASTEXITCODE` checks.
- `WL-007` & `WL-011`: Zero full-file reads over 500 lines; `sha256` and `git diff` `touched_ranges` verified via `.agents/state/ast-receipt-latest.json`.
- `WL-009`: Zero pipeline-polluting scratch patch scripts and full Windows PowerShell 5.1 + `[xml]` XAML AST compliance.

### Pillar 4: `CONTEXT_DRIFT` (25 pts — Contract & Scope Alignment)
- Verify 100% alignment between Wave 1 `signature_contract` (parameter names, CLI flags, exit codes, WinForms/WPF control names) and `touched_ranges`.

---

## 2. Gate 2 Rubric (`ui-ux-tester` — Automated E2E & Sliced Desktop UX, `>= 95%` Required)

### A. Deterministic XAML Control/Event Check & Pester v5 Smoke Suite (`50 pts`)
- Verify `xaml_control_check.unresolved_controls` in `.agents/state/ast-receipt-latest.json` is empty (`0` missing `x:Name` bindings across all `$window.FindName(...)` / `$modal.FindName(...)` calls).
- Execute `Invoke-Pester -Path ./tests` (`tests/ps_deploy.Tests.ps1`) and/or `.bat` CLI exit-code checks.

### B. WinForms / WPF Desktop UI/UX & Accessibility Audit via AST Control Slices (`50 pts`)
- Inspect `touched_ranges` (`<= 500` lines) around modified UI controls/dialogs:
  - **DPI & Layout Scaling:** Verify `MinWidth`/`MinHeight` or `AutoScaleMode = Dpi` so controls never clip on 125%/150% Windows display scaling.
  - **Keyboard & Section 508 Ergonomics:** Verify logical `TabIndex` / button placement and readable contrast ratios (`Segoe UI` >= 9pt).
  - **Thread Responsiveness:** Verify long operations update progress asynchronously without locking the main window message pump.
