---
name: windows-powershell-batch-dev
description: Production Windows application engineering skill (v4.3.2-win) covering PowerShell 5.1/7+, Batch (.bat/.cmd), WinForms/WPF STA desktop GUIs, RunspacePool concurrency, Registry/Active Directory, Rclone/Robocopy, ps2exe packaging, Dual-Engine PS 5.1/PS 7 + XAML + SHA256 Receipt Verification (WL-009, WL-011), and 500-Line Surgical AST/Graphify Slicing (WL-007).
---

# Windows, PowerShell & Batch Development Skill (`windows-powershell-batch-dev` | `v4.3.2-win`)

## 1. Hard 500-Line Read Ceiling, Surgical `edit_file` Slicing (`WL-007`), & Zero Pipeline Pollution (`WL-009`, `WL-011`)
When working with any `.ps1`, `.psm1`, `.bat`, or `.cmd` file over **500 lines** (including 8,000+ line enterprise WinForms/WPF scripts):
1. **Never Read Over 500 Lines (`WL-007`):**
   - Do **NOT** call `read_file` on the whole file or request any line range where `(EndLine - StartLine + 1) > 500` (never read `.agents/state/ast-line-graph.json` directly via `read_file`).
2. **Locate Exact Target Coordinates via `Get-PsAstGraph.ps1`:**
   ```powershell
   pwsh -NoProfile -File ".agents/skills/windows-team-orchestrator/scripts/Get-PsAstGraph.ps1" -LiteralPath $TargetFile -Query "FunctionName|RegionName|btnControl" -ExportGraphify
   ```
   - Read **only** the `StartLine`..`EndLine` (`<= 500` lines) returned for the target function, `#region`, or GUI event handler, and apply surgical edits directly with `edit_file`.
3. **Never Use Pipeline-Polluting Scratch Patch Scripts (`WL-009`):**
   - Never write ad-hoc PowerShell mutator scripts that use `Write-Output` inside functions returning source code strings (which prepends log strings to Line 1 of the target script), and always normalize mixed LF/CRLF line endings before editing.

---

## 2. PowerShell 5.1 & 7+ Architecture (`*.ps1`, `*.psm1`, `*.psd1`)
1. **Mandatory Script Header & Parameter Contracts (`WL-005`):**
   ```powershell
   [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
   param(
       [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
       [ValidateNotNullOrEmpty()]
       [string]$LiteralTargetPath
   )
   Set-StrictMode -Version Latest
   $ErrorActionPreference = 'Stop'
   ```
2. **Safe File System Enumeration (`WL-001`):**
   - Always use `-LiteralPath` on `Get-ChildItem`, `Test-Path`, `Copy-Item`, and `Remove-Item` so paths containing `[` or `]` never fail wildcard expansion.
   - Always skip `[System.IO.FileAttributes]::ReparsePoint` before recursing into subdirectories.
3. **WinForms / WPF Desktop GUI Engineering (`WL-002`):**
   - **STA Relaunch Guard:** Verify `[System.Threading.Thread]::CurrentThread.GetApartmentState() -eq 'STA'` at startup.
   - **DPI & High-Contrast Ergonomics:** Set `$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi` (or WPF `MinWidth`/`MinHeight`), `Segoe UI` font, and logical `TabIndex`.
   - **Non-Blocking UI (`RunspacePool`):** Never run `robocopy`, `rclone`, or remote WinRM/SMB jobs on the UI thread. Use `[runspacefactory]::CreateRunspacePool(1, [Environment]::ProcessorCount)` + `[hashtable]::Synchronized(@{})` and a `DispatcherTimer` / `Forms.Timer` to marshal progress back to the GUI safely.
4. **`ps2exe` Packaging & Native CLI Invocation (`WL-004`):**
   - Resolve base directory via `$BaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\') }`.
   - Package `ps_deploy.ps1` into `ps_deploy.exe` via `build_exe.ps1` (which invokes `Get-PsAstGraph.ps1` pre-flight validation and passes `-iconFile ps_deploy.ico`).
   - Normalize `robocopy.exe` exit codes (`$LASTEXITCODE -lt 8` is success; `$LASTEXITCODE -ge 8` throws an error).

---

## 3. Defensive Windows Batch Scripting (`*.bat`, `*.cmd` — `WL-003`)
1. Start every `.bat`/`.cmd` script with `@echo off` and `setlocal EnableExtensions EnableDelayedExpansion`.
2. Quote every variable expansion (`"%SCRIPT_DIR%\tool.ps1"`), provide `/?` help handling, and exit cleanly with `endlocal & exit /b %EXIT_CODE%`.

---

## 4. Mandatory 1-Second Local Dual-Engine AST (PS 5.1 + PS 7 + XAML + SHA256) & Graphify Refresh Before Handoff
Before releasing your `write_lock`, run `Get-PsAstGraph.ps1` (which validates PS 7 + PS 5.1 `Parser::ParseFile`, Line 1 header integrity, embedded `[xml]` XAML blocks + `FindName` bindings, updates `.agents/state/ast-line-graph.json` + `graphify-out/graph.json` without overwriting other files, and writes `.agents/state/ast-receipt-latest.json`):
```powershell
pwsh -NoProfile -File ".agents/skills/windows-team-orchestrator/scripts/Get-PsAstGraph.ps1" -LiteralPath $FullPath -Query "<TouchedSymbol>" -ExportGraphify
```
Record `ast_receipt` (from `.agents/state/ast-receipt-latest.json`, including `sha256`, `ps51_verified: true`, `header_clean: true`, `xaml_verified: true`, and `touched_ranges`) in your 6-field JSON Handoff Envelope.
