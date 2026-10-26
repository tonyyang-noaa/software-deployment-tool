---
trigger: glob
globs: "**/*.ps1, **/*.psm1, **/*.psd1, **/*.bat, **/*.cmd, **/*.reg, **/ps2exe*.json, **/*rclone*.conf"
description: Concise Windows, PowerShell 5.1/7+, Batch (.bat/.cmd), WinForms/WPF GUI, and ps2exe coding guardrails (v4.3.2-win) for /windows-dev-team (WL-001..WL-012).
---

# Windows, PowerShell & Batch Engineering Rules (`windows-powershell-batch-rules.md` | `v4.3.2-win`)

> **Orchestration & Slicing Reference (`WL-007`, `WL-010`):** Follow `AGENTS.md` for the 6-agent roster, `<= 500`-line `read_file` ceiling, and `Get-PsAstGraph.ps1 -Query` pre-indexing. Never read `.agents/state/ast-line-graph.json` directly via `read_file`; read `.agents/state/ast-receipt-latest.json` (`< 30` lines) instead.

## 1. PowerShell 5.1 / 7+ Guardrails (`*.ps1`, `*.psm1`, `*.psd1`)
1. **Strict Header & `SupportsShouldProcess` (`WL-005`):**
   - Declare `[CmdletBinding(SupportsShouldProcess = $true)]` on any script/function that modifies files, Registry keys, Windows Services, Scheduled Tasks, or Active Directory.
   - Enforce `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` at the top of standalone scripts/modules.
2. **ReparsePoint & LiteralPath Traversal Safety (`WL-001`):**
   - Never run unguarded `Get-ChildItem -Recurse` or raw `-Path` on user directories or SMB shares. Always use `-LiteralPath` and exclude Windows junctions/symlinks (`Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) }`).
3. **WinForms / WPF `[STAThread]` & Non-Blocking `RunspacePool` (`WL-002`):**
   - Verify `[System.Threading.Thread]::CurrentThread.GetApartmentState() -eq 'STA'` before loading `System.Windows.Forms` or `PresentationFramework`.
   - Offload long I/O (`robocopy`, `rclone`, disk scans) to a `RunspacePool` or background timer using `[hashtable]::Synchronized(@{})` so the UI thread stays responsive.
4. **`ps2exe` Base Path, Mandatory `ps_deploy.ico` Icon & Windowless Native CLI (`WL-004`, `WL-009`):**
   - Resolve base paths via `[System.AppDomain]::CurrentDomain.BaseDirectory` (with `$PSScriptRoot` fallback).
   - Package `ps_deploy.ps1` into `ps_deploy.exe` via `build_exe.ps1` with `-iconFile ps_deploy.ico` after passing `Get-PsAstGraph.ps1` Dual-Engine (PS 5.1 + PS 7 + HeaderGuard + XAML) validation.
   - Invoke native CLIs (`rclone.exe`, `robocopy.exe`) from GUI apps via `System.Diagnostics.ProcessStartInfo` with `CreateNoWindow = $true`, `UseShellExecute = $false`, and explicit `$LASTEXITCODE` checks (`robocopy` `0..7` = success; `>= 8` = failure).

## 2. Windows Batch (`*.bat`, `*.cmd`) Guardrails (`WL-003`)
1. Start every `.bat`/`.cmd` file with `@echo off` and `setlocal EnableExtensions EnableDelayedExpansion`.
2. Quote all path variables (`"%~dp0"`, `"%SOURCE_DIR%"`) and exit via `endlocal & exit /b %RET_CODE%` (never bare `exit`).
